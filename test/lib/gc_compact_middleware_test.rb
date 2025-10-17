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
    middleware.instance_variable_set(:@last_compact_time, Time.now - 7200)
    assert middleware.send(:time_to_compact?)
  end

  test 'compact runs without error' do
    app = ->(_env) { [200, {}, ['OK']] }
    middleware = GcCompactMiddleware.new(app)

    assert_nothing_raised do
      middleware.send(:compact)
    end
  end
end
