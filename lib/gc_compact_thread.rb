# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Ruby's garbage collector doesn't normally compact, leading to
# uncontrolled memory fragmentation. Here we run a periodic compactor;
# this does pause the system. We accept this because without compaction
# we run out space eventually.
# We previously scheduled this using rack middleware, but that turned
# out to be unreliable (sometimes it would never be called).
# This is simpler anyway. This configuration is inspired by
# https://www.mintbit.com/blog/
# ruby-2-dot-7-optimizing-applications-with-gc-dot-compact/
# but I've made a number of changes.

# Module to handle periodic GC compaction in a background thread
module GcCompactThread
  module_function

  # Regexes to retrieve memory information from /proc/self/status
  VM_RSS_RE  = /VmRSS:\s+(\d+)/
  VM_SWAP_RE = /VmSwap:\s+(\d+)/

  # Calculate compaction statistics.
  # We use .to_f on numerators before dividing, so that if the denominator
  # is 0 we get a NaN instead of an exception.
  def calculate_stats_diff(stats_before, stats_after, compact_info)
    {
      pages_freed: stats_before[:heap_allocated_pages] - stats_after[:heap_allocated_pages],
      objects_moved: compact_info[:moved],
      fragmentation_ratio_before: (stats_before[:heap_live_slots].to_f / stats_before[:heap_available_slots]).round(4),
      fragmentation_ratio_after: (stats_after[:heap_live_slots].to_f / stats_after[:heap_available_slots]).round(4),
      read_barrier_faults_delta: stats_after[:read_barrier_faults] - stats_before[:read_barrier_faults]
    }
  end

  require 'objspace'

  def report_class_info
    # Extract Redcarpet specific stats
    # This extracts only specific class info, so it's faster.
    [Redcarpet::Markdown, Redcarpet::Render::HTML].each do |klass|
      count = 0
      total_mem = 0
      ObjectSpace.each_object(klass) do |o|
        count += 1
        total_mem += ObjectSpace.memsize_of(o)
      end
      Rails.logger.warn "GC.compact - #{klass.name}: Count #{count}, " \
                        "Ruby-Mem: #{total_mem} bytes"
    end
    # # sleep before another long-running task
    # sleep 10
    # # Get counts and memory sizes of all instances
    # counts = Hash.new(0) # count# instances. The '0' is the default value 0
    # mem_size = Hash.new(0)
    # ObjectSpace.each_object do |o|
    #   # We use the class object directly to avoid the overhead of
    #   # .name strings for every single object in the heap.
    #   cls = o.class
    #   counts[cls] += 1
    #   mem_size[cls] += ObjectSpace.memsize_of(o)
    # rescue StandardError
    #   # Some objects might not respond
    # end

    # # Sort and take top X to avoid massive log lines
    # top_mem = mem_size.sort_by { |_, v| -v }.first(50).map { |k, v| [k.to_s, v] }.to_h
    # top_count = counts.sort_by { |_, v| -v }.first(50).map { |k, v| [k.to_s, v] }.to_h

    # Rails.logger.warn "GC.compact - Top Memory: #{top_mem}"
    # Rails.logger.warn "GC.compact - Top Counts: #{top_count}"
  end

  def compact_with_logging(mem = nil)
    return unless GC.respond_to?(:compact)

    Rails.logger.warn "GC.compact starting; (#{mem * 1.0 / (2**20)}MiB)" if mem
    stats_before = GC.stat
    compact_info = GC.compact
    stats_after = GC.stat
    Rails.logger.warn 'GC.compact completed'
    stats_diff = calculate_stats_diff(stats_before, stats_after, compact_info)
    Rails.logger.warn("GC.compact - statistics before: #{stats_before}")
    Rails.logger.warn("GC.compact - statistics afterwards: #{stats_after}")
    Rails.logger.warn("GC.compact - statistics changes: #{stats_diff}")

    report_class_info
  end

  # Return current memory use in bytes
  # The status_path parameter is primarily for testing the fallback path
  def memory_use_in_bytes(status_path = '/proc/self/status')
    # Slurp file status_path into temp string; it's expected to be smallish.
    # We need to know our total memory use, which is
    # rss (physical memory in use) + swap (memory swapped to storage)
    # File /proc/self/statm would give us rss easily, but not swap space.
    status = File.read(status_path)
    # Pull kB values out via regex
    rss  = status[VM_RSS_RE, 1].to_i
    swap = status[VM_SWAP_RE, 1].to_i

    # Log every memory use check if configured to do so
    # We log from within this method so we can provide the details
    Rails.logger.warn "GC Compacting: rss=#{rss}, swap=#{swap} bytes" if ANNOUNCE_GC_CHECK
    # Return total in bytes
    (rss + swap) * 1024
  rescue StandardError
    # Guesstimate memory from rss alone. This is useful on Macs, etc.
    `ps -o rss= -p #{Process.pid}`.to_i * 1024
  end

  # We originally compacted on a fixed period. However, that compacted
  # when we didn't need to, and it didn't compact soon enough if we did.
  # So instead, we now periodically check memory use, and we compact
  # if the memory use is too much.
  # Compacting takes a while, so once we've done it, we delay much longer
  # before checking again. After all, it's unlikely to help for a while.
  # As a result, we have 2 separate delay times.
  # Instead of `20 * 60` we could use `20.minutes`, but the latter
  # generate special types. Garbage collection is low-level;
  # we want to minimize the objects we create, and what's happening in
  # general here, to maximize the memory we recover.

  # Seconds post memory-ok before recheck
  SLEEP_AFTER_CHECK = (ENV['BADGEAPP_SLEEP_AFTER_CHECK'] || (1 * 60)).to_i
  # Seconds post memory-not-ok before recheck
  SLEEP_AFTER_COMPACT = (ENV['BADGEAPP_SLEEP_AFTER_COMPACT'] || (20 * 60)).to_i

  ANNOUNCE_GC_CHECK = ENV['BADGEAPP_ANNOUNCE_GC_CHECK'].present?

  # Repeated check if memory used is more than max_mem, and if so, compact.
  # The parameters make testing easier.
  # For tests we typically want one_time = true and
  # delay = 0 (in Ruby only false and nil are falsey; 0 is truthy).
  # The raise_exception parameter lets us test the process of
  # handling an exception within the main loop.
  # This isn't a predicate; Rubocop is misled by the name.
  # rubocop:disable Naming/PredicateMethod
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def gc_compact_as_needed(max_mem, one_time = false, delay = nil, raise_exception: false)
    loop do
      begin
        raise StandardError, 'Test exception' if raise_exception

        current_mem = memory_use_in_bytes
        if current_mem <= max_mem
          sleep(delay || SLEEP_AFTER_CHECK)
        else
          compact_with_logging(current_mem)
          sleep(delay || SLEEP_AFTER_COMPACT)
        end
      rescue StandardError => e
        Rails.logger.error "GC compact error: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") if e.backtrace
        # Exceptions suggest a serious problem. Let's not make things
        # worse by repeatedly doing them aggressively, and hope that the
        # system will manage to right itself over time.
        sleep(delay || SLEEP_AFTER_COMPACT)
      end
      break if one_time
    end
    true
  end
  # rubocop:enable Naming/PredicateMethod
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Start the background thread that runs GC compaction periodically.
  # Called from config/initializers/gc_compact_thread.rb during app initialization.
  #
  # @return [Thread] The background thread that was created
  def start_background_thread
    Thread.new do
      # By default, compact once we exceed 1GiB
      max_mem = (ENV['BADGEAPP_MEMORY_COMPACTOR_MB'] || 1024).to_i * (2**20)
      current_mem = memory_use_in_bytes
      Rails.logger.warn "GC Compacting thread if > #{max_mem} bytes, currently #{current_mem} bytes"
      gc_compact_as_needed(max_mem)
    end
  end
end
