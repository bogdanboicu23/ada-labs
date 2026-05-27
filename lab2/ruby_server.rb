# frozen_string_literal: true

require 'bunny'
require 'securerandom'
require 'json'

user             = 'guest'
password         = 'guest'
host             = 'rabbitmq:5672'
queue_name       = 'crypto-puzzle-inquiries'

WORKER_COUNT = 3
REPLY_TIMEOUT = 120  # seconds to wait for all workers

# Scale the nonce range per worker based on difficulty.
# Expected attempts to find d leading hex zeroes ≈ 16^d.
# We multiply by 2 for safety margin, then split across workers.
def nonce_range_size(difficulty)
  total = (16**difficulty) * 2 / WORKER_COUNT
  # Clamp to a minimum so low difficulties still have reasonable chunks
  [total, 500_000].max
end

def print_performance_table(replies, difficulty)
  puts ''
  puts '=' * 70
  puts "PERFORMANCE RESULTS (difficulty = #{difficulty})"
  puts '=' * 70
  printf "%-12s %12s %14s %14s   %s\n", 'Worker', 'Time (ms)', 'Hashes', 'Hash Rate', 'Found?'
  puts '-' * 70

  # Sort by time (fastest first)
  sorted = replies.sort_by { |r| r['time_taken_ms'] }

  sorted.each do |r|
    time_ms = r['time_taken_ms']
    hashes  = r['hashes_computed']
    rate    = time_ms > 0 ? (hashes / (time_ms / 1000.0)).to_i : 0
    found   = r['found'] ? 'YES' : 'no'

    printf "%-12s %12.2f %14d %12d/s   %s\n",
           r['worker'], time_ms, hashes, rate, found
  end

  winner = sorted.first
  solution_reply = replies.find { |r| r['found'] }

  puts ''
  puts "Winner: #{winner['worker']} (#{winner['time_taken_ms'].round(2)} ms)"
  if solution_reply
    puts "Solution: #{solution_reply['solution']}"
  else
    puts 'Solution: (none found by any worker)'
  end
  puts '=' * 70
  puts ''
end

def print_aggregate_summary(aggregate_stats)
  puts ''
  puts '=' * 70
  puts 'AGGREGATE PERFORMANCE SUMMARY'
  puts '=' * 70
  printf "%-12s %8s %14s %14s %8s\n",
         'Worker', 'Runs', 'Avg Time (ms)', 'Avg Hash Rate', 'Wins'
  puts '-' * 70

  aggregate_stats.each do |worker, stats|
    next if stats[:runs].zero?

    avg_time = stats[:total_time_ms] / stats[:runs]
    avg_rate = stats[:total_rate] / stats[:runs]

    printf "%-12s %8d %14.2f %12d/s %8d\n",
           worker, stats[:runs], avg_time, avg_rate, stats[:wins]
  end
  puts '=' * 70
  puts ''
end

# ── Aggregate stats tracking ──────────────────────────────────────────────────
aggregate_stats = Hash.new do |h, k|
  h[k] = { runs: 0, total_time_ms: 0.0, total_rate: 0, wins: 0 }
end
total_runs = 0

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

lock               = Mutex.new
condition          = ConditionVariable.new
replies            = []
current_corr_id    = nil

channel     = connection.create_channel
exchange    = channel.default_exchange
queue       = channel.queue(queue_name, auto_delete: true)

# Anonymous exclusive queue — auto-deleted when this connection closes,
# so no stale replies accumulate between sessions.
reply_queue = channel.queue('', exclusive: true)

reply_queue.subscribe do |_delivery_info, properties, payload|
  lock.synchronize do
    # Filter by correlation_id to ignore stale replies from previous runs
    next unless properties.correlation_id == current_corr_id

    result = JSON.parse(payload)
    replies << result
    puts "  [Reply #{replies.size}/#{WORKER_COUNT}] #{result['worker']}: " \
         "#{result['found'] ? result['solution'] : 'no solution'} " \
         "(#{result['time_taken_ms']} ms, #{result['hashes_computed']} hashes)"

    # Signal when all workers have replied
    condition.signal if replies.size >= WORKER_COUNT
  end
end

begin
  loop do
    puts 'Press Ctrl+C to exit'
    puts 'Enter difficulty of puzzle from 1 to 8:'

    difficulty = $stdin.gets.to_i
    if (1..8).include?(difficulty)
      lock.synchronize do
        replies.clear
        current_corr_id = SecureRandom.uuid
      end

      range_size = nonce_range_size(difficulty)

      WORKER_COUNT.times do |i|
        payload = {
          string:      'Hello World',
          difficulty:  difficulty,
          nonce_start: i * range_size,
          nonce_end:   (i + 1) * range_size - 1
        }
        exchange.publish(
          payload.to_json,
          routing_key:    queue.name,
          correlation_id: current_corr_id,
          reply_to:       reply_queue.name
        )
        puts "Dispatched to worker #{i + 1}: nonce #{payload[:nonce_start]}..#{payload[:nonce_end]}"
      end

      puts "Waiting for all #{WORKER_COUNT} workers (timeout: #{REPLY_TIMEOUT}s)..."

      deadline = Time.now + REPLY_TIMEOUT
      lock.synchronize do
        while replies.size < WORKER_COUNT
          remaining = deadline - Time.now
          if remaining <= 0
            puts "\nTimeout! Only received #{replies.size}/#{WORKER_COUNT} replies."
            break
          end
          condition.wait(lock, remaining)
        end
      end

      if replies.any?
        print_performance_table(replies, difficulty)

        # Update aggregate stats
        total_runs += 1
        sorted = replies.sort_by { |r| r['time_taken_ms'] }
        winner_name = sorted.first['worker']

        replies.each do |r|
          stats = aggregate_stats[r['worker']]
          stats[:runs] += 1
          stats[:total_time_ms] += r['time_taken_ms']
          time_s = r['time_taken_ms'] / 1000.0
          stats[:total_rate] += time_s > 0 ? (r['hashes_computed'] / time_s).to_i : 0
        end
        aggregate_stats[winner_name][:wins] += 1
      else
        puts 'No replies received from any worker.'
      end
    else
      puts "Incorrect value. You've introduced #{difficulty}. Valid range is 1..8"
    end
  end
rescue Interrupt => _e
  puts "\n\nShutting down..."
  if total_runs > 0
    print_aggregate_summary(aggregate_stats)
    puts "Total runs completed: #{total_runs}"
  end
  channel.close
  connection.close
  exit(0)
end
