using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

var factory = new ConnectionFactory
{
    // RabbitMQ.Client splits the URI into parts, unlike Bunny which takes
    // the full amqp:// string. The hostname here is the Docker service name.
    HostName = "rabbitmq",
    Port     = 5672,
    UserName = "guest",
    Password = "guest"
};

await using var connection = await factory.CreateConnectionAsync();
await using var channel    = await connection.CreateChannelAsync();

// ── Queue declaration — same as channel.queue(queue_name, auto_delete: true) ──
// Both sides (server and worker) MUST declare the queue with identical options.
// If they disagree (e.g. one says auto_delete: true and the other false),
// RabbitMQ raises a 406 PRECONDITION_FAILED error and closes the channel.
await channel.QueueDeclareAsync(
    queue:      "crypto-puzzle-inquiries",
    durable:    false,
    exclusive:  false,
    autoDelete: true   // matches auto_delete: true in the Ruby server
);

// ── Consumer — same role as queue.subscribe(block: true) do |...| ─────────────
var consumer = new AsyncEventingBasicConsumer(channel);

consumer.ReceivedAsync += async (_, ea) =>
{
    // Parse the JSON payload — same as JSON.parse(payload) in Ruby
    var payload    = JsonSerializer.Deserialize<JsonElement>(ea.Body.Span);
    string str     = payload.GetProperty("string").GetString()!;
    int difficulty = payload.GetProperty("difficulty").GetInt32();
    int nonceStart = payload.GetProperty("nonce_start").GetInt32();
    int nonceEnd   = payload.GetProperty("nonce_end").GetInt32();

    Console.WriteLine($"[C#] Received task: nonce {nonceStart}..{nonceEnd}");

    var (solution, hashesComputed, timeTakenMs) = SolvePuzzle(str, difficulty, nonceStart, nonceEnd);

    if (solution != null)
        Console.WriteLine($"[C#] Found solution: {solution}");
    else
        Console.WriteLine($"[C#] No solution in range {nonceStart}..{nonceEnd}");

    Console.WriteLine($"[C#] Finished in {timeTakenMs:F2} ms ({hashesComputed} hashes)");

    var reply = JsonSerializer.Serialize(new
    {
        worker          = "CSharp",
        solution        = solution,
        found           = solution != null,
        nonce_start     = nonceStart,
        nonce_end       = nonceEnd,
        hashes_computed = hashesComputed,
        time_taken_ms   = Math.Round(timeTakenMs, 2)
    });

    var replyProps = new BasicProperties
    {
        CorrelationId = ea.BasicProperties.CorrelationId
    };

    await channel.BasicPublishAsync(
        exchange:        string.Empty,
        routingKey:      ea.BasicProperties.ReplyTo!,
        mandatory:       false,
        basicProperties: replyProps,
        body:            Encoding.UTF8.GetBytes(reply)
    );
};

await channel.BasicConsumeAsync("crypto-puzzle-inquiries", autoAck: true, consumer: consumer);

Console.WriteLine("[C#] Waiting for tasks. Ctrl+C to exit.");
await Task.Delay(Timeout.Infinite);  // keep the process alive, like block: true in Ruby

// ── Puzzle solver — searches the assigned nonce range [nonceStart, nonceEnd] ──
// Returns (solution, hashesComputed, timeTakenMs)
static (string? solution, int hashesComputed, double timeTakenMs) SolvePuzzle(
    string str, int difficulty, int nonceStart, int nonceEnd)
{
    string target = new string('0', difficulty);
    int hashesComputed = 0;
    var stopwatch = Stopwatch.StartNew();

    for (int n = nonceStart; n <= nonceEnd; n++)
    {
        hashesComputed++;
        string candidate = str + n;

        byte[] hash    = SHA256.HashData(Encoding.UTF8.GetBytes(candidate));
        string hexHash = Convert.ToHexString(hash).ToLowerInvariant();

        if (hexHash.StartsWith(target))
        {
            stopwatch.Stop();
            return (candidate, hashesComputed, stopwatch.Elapsed.TotalMilliseconds);
        }
    }

    stopwatch.Stop();
    return (null, hashesComputed, stopwatch.Elapsed.TotalMilliseconds);
}