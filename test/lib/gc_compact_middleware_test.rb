# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'gc_compact_middleware'

# Test our garbage collection compactor middleware.
class GcCompactMiddlewareTest < ActiveSupport::TestCase
  setup do
    @app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
    @env = {}
  end

  test 'initializes with correct defaults' do
    middleware = GcCompactMiddleware.new(@app)

    assert_equal 7200, middleware.instance_variable_get(:@interval) # 120 min default
    assert_instance_of Mutex, middleware.instance_variable_get(:@mutex)
    assert middleware.instance_variable_get(:@first_call)
    assert_not_nil middleware.instance_variable_get(:@last_compact_time)
  end

  test 'initializes with custom interval from parameter' do
    middleware = GcCompactMiddleware.new(@app, interval_seconds: 3600)

    assert_equal 3600, middleware.instance_variable_get(:@interval) # 60 minutes
    assert_instance_of Mutex, middleware.instance_variable_get(:@mutex)
    assert middleware.instance_variable_get(:@first_call)
    assert_not_nil middleware.instance_variable_get(:@last_compact_time)
  end

  test 'logs first request only' do
    middleware = GcCompactMiddleware.new(@app)

    # First call should log
    assert middleware.instance_variable_get(:@first_call)
    middleware.call(@env)
    assert_not middleware.instance_variable_get(:@first_call)

    # Subsequent calls should not log (first_call is now false)
    middleware.call(@env)
    assert_not middleware.instance_variable_get(:@first_call)
  end

  test 'does not schedule compaction when interval has not expired' do
    middleware = GcCompactMiddleware.new(@app)
    env = { 'rack.after_reply' => [] }

    # Interval has not expired (just initialized)
    middleware.call(env)

    # Should NOT have scheduled compaction
    assert_empty env['rack.after_reply']
  end

  test 'schedules compaction when interval has expired' do
    middleware = GcCompactMiddleware.new(@app)
    env = { 'rack.after_reply' => [] }

    # Set time to past so interval has expired
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    middleware.call(env)

    # Should have scheduled compaction
    assert_equal 1, env['rack.after_reply'].length
    assert_instance_of Proc, env['rack.after_reply'].first
  end

  test 'updates last_compact_time when scheduling' do
    middleware = GcCompactMiddleware.new(@app)
    env = { 'rack.after_reply' => [] }

    old_time = Time.zone.now - 7200
    middleware.instance_variable_set(:@last_compact_time, old_time)

    middleware.call(env)

    new_time = middleware.instance_variable_get(:@last_compact_time)
    assert new_time > old_time
    assert_in_delta Time.zone.now, new_time, 1 # Within 1 second of now
  end

  test 'call method returns correct response' do
    middleware = GcCompactMiddleware.new(@app)
    env = {}

    status, headers, body = middleware.call(env)

    assert_equal 200, status
    assert_equal({ 'Content-Type' => 'text/plain' }, headers)
    assert_equal ['OK'], body
  end

  test 'scheduled lambda calls compact without error' do
    middleware = GcCompactMiddleware.new(@app)
    env = { 'rack.after_reply' => [] }

    # Set time to past so compaction gets scheduled
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    middleware.call(env)

    # Execute the scheduled lambda
    scheduled_proc = env['rack.after_reply'].first
    assert_nothing_raised do
      scheduled_proc.call
    end
  end

  test 'compact method runs GC.compact without error' do
    middleware = GcCompactMiddleware.new(@app)

    # Call the private compact method
    assert_nothing_raised do
      middleware.send(:compact)
    end
  end

  test 'thread safety - only one compaction scheduled when multiple threads race' do
    middleware = GcCompactMiddleware.new(@app)

    # Set time to past so interval has expired
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    # Simulate multiple threads calling simultaneously
    envs = Array.new(10) { { 'rack.after_reply' => [] } }
    threads =
      envs.map do |env|
        Thread.new { middleware.call(env) }
      end
    threads.each(&:join)

    # Count total scheduled compactions across all envs
    total_scheduled = envs.sum { |env| env['rack.after_reply']&.length || 0 }

    # Only one should have been scheduled (first thread to acquire mutex)
    assert_equal 1, total_scheduled
  end

  test 'initializes env rack.after_reply if not present' do
    middleware = GcCompactMiddleware.new(@app)
    env = {} # No rack.after_reply key

    # Set time to past so compaction gets scheduled
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    middleware.call(env)

    # Should have created the array and added the proc
    assert_not_nil env['rack.after_reply']
    assert_equal 1, env['rack.after_reply'].length
  end
end
