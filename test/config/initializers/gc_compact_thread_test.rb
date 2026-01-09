# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Load the initializer code that defines gc_compact_as_needed
require_relative '../../../config/initializers/gc_compact_thread'

class GcCompactThreadTest < ActiveSupport::TestCase
  # Test current_rss_memory with default.
  # It will try to read from /proc/self/statm, which works on Linux.
  # MacOS will fail and use its alternative, but still give an answer.
  test 'current_rss_memory works by default' do
    rss = GcCompactThread.current_rss_memory
    # We don't know the current value, but we know these must be true.
    assert rss.is_a?(Integer)
    assert rss.positive?
  end

  # Test current_rss_memory with fixture file.
  # This lets us test Linux code path even if running on macOS.
  # It also lets us verify that the calculations are exactly correct.
  test 'current_rss_memory reads from statm fixture file' do
    fixture_path = Rails.root.join('test/fixtures/files/proc_statm_sample').to_s
    rss = GcCompactThread.current_rss_memory(fixture_path)
    # Fixture has 50000 pages in field 2 (RSS), so 50000 * 4096 = 204800000
    assert_equal 204_800_000, rss
  end

  # Test current_rss_memory fallback to ps command when file doesn't exist
  test 'current_rss_memory falls back to ps when statm unavailable' do
    rss = GcCompactThread.current_rss_memory('/nonexistent/path')
    # We don't know the current value, but we know these must be true.
    assert rss.is_a?(Integer)
    assert rss.positive?
  end

  # Test the GC compactor when memory is below threshold (no compaction)
  test 'gc_compact_as_needed when memory is below threshold' do
    # Use a very large memsize to ensure current memory is below it
    memsize = 1024 * 1024 * 1024 * 100 # 100 GiB, above any reasonable RSS
    assert GcCompactThread.gc_compact_as_needed(memsize, true, 0)
  end

  # Test the GC compactor when memory exceeds threshold (triggers compaction)
  test 'gc_compact_as_needed when memory exceeds threshold' do
    # Use a very small memsize to ensure current memory exceeds it
    memsize = 1 # 1 byte, will definitely be exceeded
    assert GcCompactThread.gc_compact_as_needed(memsize, true, 0)
  end

  # Test exception handling - thread survives exceptions
  test 'gc_compact_as_needed handles exceptions and continues' do
    # Use raise_exception parameter to trigger exception handling
    assert GcCompactThread.gc_compact_as_needed(1, true, 0, raise_exception: true)
  end

  # Test compact_with_logging directly to ensure full coverage
  test 'compact_with_logging performs compaction if GC.compact available' do
    # This test ensures calculate_compaction_stats is covered
    # Call with rss value to test logging path - should not raise
    assert_nothing_raised { GcCompactThread.compact_with_logging(100_000_000) }
  end
end
