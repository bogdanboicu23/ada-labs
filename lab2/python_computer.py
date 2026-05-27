import pika
import hashlib
import json
import time

user       = 'guest'
password   = 'guest'
host       = 'rabbitmq'
queue_name = 'crypto-puzzle-inquiries'

def solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end):
    """
    Search for a nonce n in [nonce_start, nonce_end] such that
    SHA256(string + str(n)) starts with `difficulty` hex zeroes.
    Returns a dict with solution (or None), hashes_computed, and time_taken_ms.
    """
    target = '0' * difficulty
    hashes_computed = 0

    start_time = time.monotonic()

    for n in range(nonce_start, nonce_end + 1):
        hashes_computed += 1
        candidate = string + str(n)
        digest = hashlib.sha256(candidate.encode('utf-8')).hexdigest()
        if digest.startswith(target):
            elapsed_ms = (time.monotonic() - start_time) * 1000.0
            return {'solution': candidate, 'hashes_computed': hashes_computed, 'time_taken_ms': elapsed_ms}

    elapsed_ms = (time.monotonic() - start_time) * 1000.0
    return {'solution': None, 'hashes_computed': hashes_computed, 'time_taken_ms': elapsed_ms}

def connect_with_retry(max_retries=10, delay=3):
    """Retry connecting to RabbitMQ — it may not be ready when the container starts."""
    credentials = pika.PlainCredentials(user, password)
    for attempt in range(1, max_retries + 1):
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host=host, port=5672, credentials=credentials)
            )
            print(f'[Python] Connected to RabbitMQ (attempt {attempt})')
            return connection
        except pika.exceptions.AMQPConnectionError:
            print(f'[Python] RabbitMQ not ready, retrying in {delay}s ({attempt}/{max_retries})...')
            time.sleep(delay)
    raise RuntimeError('Could not connect to RabbitMQ after all retries')

def main():
    connection = connect_with_retry()
    channel = connection.channel()

    # Declare the queue with the same properties as the server.
    # If properties don't match what RabbitMQ already has for this queue,
    # it raises a 406 PRECONDITION_FAILED error — so auto_delete must match.
    channel.queue_declare(queue=queue_name, auto_delete=True)

    def on_message(ch, method, properties, body):
        payload    = json.loads(body)
        string     = payload['string']
        difficulty = payload['difficulty']
        nonce_start = payload['nonce_start']
        nonce_end   = payload['nonce_end']

        print(f'[Python] Received task: nonce {nonce_start}..{nonce_end}')

        result = solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end)

        solution = result['solution']
        if solution:
            print(f'[Python] Found solution: {solution}')
        else:
            print(f'[Python] No solution in range {nonce_start}..{nonce_end}')

        print(f'[Python] Finished in {result["time_taken_ms"]:.2f} ms ({result["hashes_computed"]} hashes)')

        reply = json.dumps({
            'worker':          'Python',
            'solution':        solution,
            'found':           solution is not None,
            'nonce_start':     nonce_start,
            'nonce_end':       nonce_end,
            'hashes_computed': result['hashes_computed'],
            'time_taken_ms':   round(result['time_taken_ms'], 2)
        })

        ch.basic_publish(
            exchange='',
            routing_key=properties.reply_to,
            properties=pika.BasicProperties(
                correlation_id=properties.correlation_id
            ),
            body=reply.encode('utf-8')
        )

    channel.basic_consume(
        queue=queue_name,
        on_message_callback=on_message,
        auto_ack=True
    )

    print('[Python] Waiting for tasks. Ctrl+C to exit.')
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()

    connection.close()

if __name__ == '__main__':
    main()