# frozen_string_literal: true

require 'bunny'
require 'digest/sha2'
require 'json'

user       = 'guest'
password   = 'guest'
host       = 'rabbitmq:5672'
queue_name = 'crypto-puzzle-inquiries'

def solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end)
  sha256 = Digest::SHA256.new
  needle = '0' * difficulty
  hashes_computed = 0

  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  (nonce_start..nonce_end).each do |n|
    hashes_computed += 1
    solution_candidate = string + n.to_s
    result = sha256.hexdigest(solution_candidate)
    if result[0...difficulty] == needle
      elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
      return { solution: solution_candidate, hashes_computed: hashes_computed, time_taken_ms: elapsed_ms }
    end
  end

  elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
  { solution: nil, hashes_computed: hashes_computed, time_taken_ms: elapsed_ms }
end

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

channel  = connection.create_channel
exchange = channel.default_exchange
queue    = channel.queue(queue_name, auto_delete: true)

begin
  puts '[Ruby] Waiting for tasks. Ctrl+C to exit.'

  queue.subscribe(block: true) do |_delivery_info, properties, payload|
    json_payload = JSON.parse(payload)
    nonce_start = json_payload['nonce_start']
    nonce_end   = json_payload['nonce_end']

    puts "[Ruby] Received task: nonce #{nonce_start}..#{nonce_end}"

    result = solve_crypto_puzzle(
      json_payload['string'],
      json_payload['difficulty'],
      nonce_start,
      nonce_end
    )

    reply = {
      worker:          'Ruby',
      solution:        result[:solution],
      found:           !result[:solution].nil?,
      nonce_start:     nonce_start,
      nonce_end:       nonce_end,
      hashes_computed: result[:hashes_computed],
      time_taken_ms:   result[:time_taken_ms].round(2)
    }.to_json

    puts "[Ruby] Finished: #{result[:solution] ? "found #{result[:solution]}" : 'no solution'} in #{result[:time_taken_ms].round(2)} ms"

    exchange.publish(
      reply,
      routing_key:    properties.reply_to,
      correlation_id: properties.correlation_id
    )
  end
rescue Interrupt => _e
  channel.close
  connection.close
  exit(0)
end