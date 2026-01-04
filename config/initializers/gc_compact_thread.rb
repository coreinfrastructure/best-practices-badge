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
    Rails.logger.warn 'GC.compact started'
    stats_before = GC.stat
    compact_info = GC.compact
    stats_after = GC.stat
    Rails.logger.warn 'GC.compact completed'
    stats = calculate_compaction_stats(stats_before, stats_after, compact_info)
    Rails.logger.warn("GC.compact statistics: #{stats}")
  end

  # Run gc periodically.
  # This isn't really a predicate.
  # rubocop:disable Naming/PredicateMethod
  def periodically_run_gc_compact(interval, one_time = false)
    Rails.logger.warn 'Function periodically_run_gc_compact started'
    loop do
      sleep interval.seconds
      compact_with_logging
      break if one_time
    end
    true
  end
  # rubocop:enable Naming/PredicateMethod
end

# Create thread to run GC.compact periodically
Rails.application.config.after_initialize do
  Thread.new do
    interval = (ENV['BADGEAPP_GC_COMPACT_MINUTES'] || 120).to_i * 60
    Rails.logger.warn "Compacting thread interval=#{@interval}sec"
    GcCompactThread.periodically_run_gc_compact(interval)
  end
end
