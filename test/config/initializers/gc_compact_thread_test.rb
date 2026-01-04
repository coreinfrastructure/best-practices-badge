# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'minitest/mock'

# Load the initializer code that defines periodically_run_gc_compact
require_relative '../../../config/initializers/gc_compact_thread'

# Test the periodic GC compactor thread functionality.
class GcCompactThreadTest < ActiveSupport::TestCase
  # Helper to capture GC.compact calls using singleton method override
  def with_gc_compact_tracking
    call_count = 0
    original_compact = GC.method(:compact)

    GC.define_singleton_method(:compact) do
      call_count += 1
    end

    yield call_count

    call_count
  ensure
    # Restore original compact method
    GC.define_singleton_method(:compact, original_compact) if original_compact
  end

  test 'periodically_run_gc_compact runs once with one_time=true and interval=1' do
    start_time = Time.current

    call_count =
      with_gc_compact_tracking do
        GcCompactThread.periodically_run_gc_compact(1, true)
      end

    elapsed = Time.current - start_time

    # Should have called GC.compact exactly once
    assert_equal 1, call_count, 'GC.compact should be called exactly once'

    # Should have slept for approximately 1 second
    assert elapsed >= 1, "Should sleep for at least 1 second, slept #{elapsed}"
    assert elapsed < 2, "Should not sleep for more than 2 seconds, slept #{elapsed}"
  end

  test 'periodically_run_gc_compact logs all expected messages' do
    mock_logger = Object.new

    def mock_logger.warn(message)
      @messages ||= []
      @messages << message
    end

    def mock_logger.messages
      @messages || []
    end

    Rails.stub :logger, mock_logger do
      with_gc_compact_tracking do
        GcCompactThread.periodically_run_gc_compact(1, true)
      end
    end

    assert_equal 3, mock_logger.messages.length
    assert_equal 'periodically_run_gc_compact started.', mock_logger.messages.first
    assert_equal 'GC.compact started', mock_logger.messages[1]
    assert_equal 'GC.compact completed', mock_logger.messages[2]
  end
  test 'periodically_run_gc_compact sleeps for correct interval' do
    start_time = Time.current

    with_gc_compact_tracking do
      GcCompactThread.periodically_run_gc_compact(1, true)
    end

    elapsed = Time.current - start_time

    # Verify sleep duration (should be approximately 1 second)
    assert elapsed >= 1, 'Should sleep for at least 1 second (interval)'
    assert elapsed < 2, 'Should sleep for less than 2 seconds'
  end

  test 'periodically_run_gc_compact exits loop when one_time is true' do
    call_count =
      with_gc_compact_tracking do
        GcCompactThread.periodically_run_gc_compact(1, true)
      end

    # Should only iterate once
    assert_equal 1, call_count, 'Should only run one iteration when one_time=true'
  end
  test 'periodically_run_gc_compact continues loop when one_time is false' do
    call_count_holder = { count: 0 }

    thread =
      Thread.new do
        # Override GC.compact in this thread
        original_compact = GC.method(:compact)
        GC.define_singleton_method(:compact) do
          call_count_holder[:count] += 1
        end

        begin
          GcCompactThread.periodically_run_gc_compact(0.1, false)
        ensure
          # Restore original
          GC.define_singleton_method(:compact, original_compact)
        end
      end

    # Let it run for a bit (should complete ~5 iterations in 0.6 seconds)
    sleep 0.6

    # Kill the thread
    thread.kill
    thread.join

    # Should have run multiple times
    assert call_count_holder[:count] >= 2,
           "Should run multiple iterations when one_time=false, ran #{call_count_holder[:count]} times"
  end

  test 'periodically_run_gc_compact with different interval values' do
    # Test with interval=2
    start_time = Time.current

    with_gc_compact_tracking do
      GcCompactThread.periodically_run_gc_compact(2, true)
    end

    elapsed = Time.current - start_time

    # Should sleep for approximately 2 seconds
    assert elapsed >= 2, "Should sleep for at least 2 seconds, slept #{elapsed}"
    assert elapsed < 3, "Should sleep for less than 3 seconds, slept #{elapsed}"
  end

  test 'function completes successfully without errors' do
    # Just ensure the function runs without raising exceptions
    assert_nothing_raised do
      # Use very short interval for speed
      with_gc_compact_tracking do
        GcCompactThread.periodically_run_gc_compact(1, true)
      end
    end
  end
end
