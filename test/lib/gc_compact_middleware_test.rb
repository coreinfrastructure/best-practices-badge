# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'gc_compact_middleware'

# Test our garbage collection compactor.
class GcCompactMiddlewareTest < ActiveSupport::TestCase
  test 'checks time correctly' do
    app = ->(_env) { [200, {}, ['OK']] }
    middleware = GcCompactMiddleware.new(app)

    # Should not compact immediately after initialization
    assert_not middleware.send(:time_to_compact?)

    # Should compact after interval expires
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)
    assert middleware.send(:time_to_compact?)
  end

  test 'compact runs without error' do
    app = ->(_env) { [200, {}, ['OK']] }
    middleware = GcCompactMiddleware.new(app)

    assert_nothing_raised do
      middleware.send(:compact)
    end
  end

  test 'schedule_compact schedules after interval' do
    app = ->(_env) { [200, {}, ['OK']] }
    middleware = GcCompactMiddleware.new(app)
    env = { 'rack.after_reply' => [] }

    # Set time to past so interval has expired
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    middleware.send(:schedule_compact, env)

    # Should have scheduled a callback
    assert_equal 1, env['rack.after_reply'].length
  end

  test 'call method returns response and schedules when interval expired' do
    app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
    middleware = GcCompactMiddleware.new(app)
    env = { 'rack.after_reply' => [] }

    # Set time to past so interval has expired
    middleware.instance_variable_set(:@last_compact_time, Time.zone.now - 7200)

    status, headers, body = middleware.call(env)

    # Should return app response
    assert_equal 200, status
    assert_equal({ 'Content-Type' => 'text/plain' }, headers)
    assert_equal ['OK'], body

    # Should have scheduled compaction
    assert_equal 1, env['rack.after_reply'].length
  end
end
