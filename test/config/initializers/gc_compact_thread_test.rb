# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Load the initializer code that defines gc_compact_as_needed
require_relative '../../../config/initializers/gc_compact_thread'

class GcCompactThreadTest < ActiveSupport::TestCase
  # Test current_rss_memory with normal /proc/self/statm path
  # This directly works on Linux; MacOS will fail and use its alternative
  test 'current_rss_memory reads from default /proc/self/statm' do
    rss = GcCompactThread.current_rss_memory
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
end
