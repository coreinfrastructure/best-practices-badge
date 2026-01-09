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

  def calculate_compaction_stats(stats_before, stats_after, compact_info)
    {
      pages_freed: stats_before[:heap_allocated_pages] - stats_after[:heap_allocated_pages],
      objects_moved: compact_info[:moved],
      fragmentation_ratio_before: (stats_before[:heap_live_slots].to_f / stats_before[:heap_available_slots]).round(4),
      fragmentation_ratio_after: (stats_after[:heap_live_slots].to_f / stats_after[:heap_available_slots]).round(4),
      read_barrier_faults_delta: stats_after[:read_barrier_faults] - stats_before[:read_barrier_faults]
    }
  end

  def compact_with_logging
    stats_before = GC.stat
    compact_info = GC.compact
    stats_after = GC.stat
    Rails.logger.warn 'GC.compact completed'
    stats = calculate_compaction_stats(stats_before, stats_after, compact_info)
    Rails.logger.warn("GC.compact statistics: #{stats}")
  end

  # Return current RSS memory in bytes (Linux/macOS)
  def current_rss_memory
    # /proc/self/statm is faster than `ps` if on Linux, so try it first
    File.read('/proc/self/statm').split[1].to_i * 4096
  rescue StandardError
    `ps -o rss= -p #{Process.pid}`.to_i * 1024
  end

  # We originally compacted on a fixed period. However, that compacted
  # when we didn't need to, and it didn't compact soon enough if we did.
  # So instead, we periodically check, and compact again if it's too much.
  # Compacting takes a while. Once we've done it, even if we're using
  # too much memory, it's unlikely to help for a while.
  # As a result, we have 2 separate times.
  SLEEP_AFTER_CHECK = 1 * 60 # seconds after memory-ok before recheck
  SLEEP_AFTER_COMPACT = 10 * 60 # seconds after memory exceeded before recheck

  # Repeated check if memory used is more than memsize, and if so, compact.
  # The one_time and delay parameters makes testing easier.
  # This isn't really a predicate.
  # rubocop:disable Naming/PredicateMethod
  def check_gc_compact(memsize, one_time = false, delay = nil)
    loop do
      rss = current_rss_memory
      if rss <= memsize
        sleep(delay || SLEEP_AFTER_CHECK)
      else
        Rails.logger.warn "GC.compact starting; (#{rss * 1.0 / (2**20)}MiB)"
        compact_with_logging
        sleep(delay || SLEEP_AFTER_COMPACT)
      end
      break if one_time
    end
    true
  end
  # rubocop:enable Naming/PredicateMethod

  # Start the background thread that runs GC compaction periodically.
  # Called from config/initializers/gc_compact_thread.rb during app initialization.
  #
  # @return [Thread] The background thread that was created
  def start_background_thread
    Thread.new do
      # By default, compact once we exceed 1GiB
      memsize = (ENV['BADGEAPP_MEMORY_COMPACTOR_MB'] || 1024).to_i * (2**20)
      Rails.logger.warn "Compacting thread if > #{memsize} bytes"
      check_gc_compact(memsize)
    end
  end
end
