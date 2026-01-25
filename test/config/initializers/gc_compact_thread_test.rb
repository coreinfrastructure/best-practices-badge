# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Load the initializer code that defines gc_compact_as_needed
require_relative '../../../config/initializers/gc_compact_thread'

class GcCompactThreadTest < ActiveSupport::TestCase
  # Test memory_use_in_bytes with default.
  # It will try to read from /proc/self/status, which works on Linux.
  # MacOS will fail and use its alternative, but still give an answer.
  test 'memory_use_in_bytes works by default' do
    current_mem = GcCompactThread.memory_use_in_bytes
    # We don't know the current value, but we know these must be true.
    assert current_mem.is_a?(Integer)
    assert current_mem.positive?
  end

  # Test memory_use_in_bytes with fixture file.
  # This lets us test Linux code path even if running on macOS.
  # It also lets us verify that the calculations are exactly correct.
  test 'memory_use_in_bytes reads from status fixture file' do
    fixture_path = Rails.root.join('test/fixtures/files/proc_status_sample').to_s
    current_mem = GcCompactThread.memory_use_in_bytes(fixture_path)
    # Fixture has 1952 RSS + 1 swap in K
    assert_equal (1952 + 1) * 1024, current_mem
  end

  # Test memory_use_in_bytes fallback to ps command when file doesn't exist
  test 'memory_use_in_bytes falls back to ps when status unavailable' do
    current_mem = GcCompactThread.memory_use_in_bytes('/nonexistent/path')
    # We don't know the current value, but we know these must be true.
    assert current_mem.is_a?(Integer)
    assert current_mem.positive?
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
    # Call with mem value to test logging path - should not raise
    assert_nothing_raised { GcCompactThread.compact_with_logging(100_000_000) }
  end

  test 'size_to_bucket' do
    assert_equal '0...100', GcCompactThread.size_to_bucket(50)
    assert_equal '100...1K', GcCompactThread.size_to_bucket(100)
    assert_equal '100...1K', GcCompactThread.size_to_bucket(999)
    assert_equal '1K...10K', GcCompactThread.size_to_bucket(1000)
    assert_equal '1K...10K', GcCompactThread.size_to_bucket(9999)
    assert_equal '10K...100K', GcCompactThread.size_to_bucket(10_000)
    assert_equal '10K...100K', GcCompactThread.size_to_bucket(99_999)
    assert_equal '100K+', GcCompactThread.size_to_bucket(100_000)
    assert_equal '100K+', GcCompactThread.size_to_bucket(500_000)
    assert_equal '100K+', GcCompactThread.size_to_bucket(10_000_000)
  end

  # Test report_string_analysis with large strings to ensure coverage of
  # the large string preview code path (lines that collect strings > 50KB)
  test 'report_string_analysis covers large string detection' do
    # Create a large unfrozen string (> 50KB) that will be detected
    # Use a distinctive prefix so we can verify it was found
    large_string = 'LARGE_STRING_TEST_MARKER_' + ('x' * 60_000)

    # Keep a reference to prevent GC from collecting it during the test
    # The string must exist in ObjectSpace when report_string_analysis runs
    assert large_string.bytesize > 50_000, 'Test string must be > 50KB'

    # Call report_string_analysis - should not raise and should log the large string
    assert_nothing_raised { GcCompactThread.report_string_analysis }

    # The large_string variable keeps the string alive until here
    assert large_string.present?
  end
end
