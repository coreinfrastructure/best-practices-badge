# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class CorsLibraryTest < ActiveSupport::TestCase
  test 'CORS library middleware stack location check in production' do
    # Because of the way it works, Rack::Cors *must* be first in the Rack
    # middleware stack, as documented here: https://github.com/cyu/rack-cors
    # This test verifies this precondition, because it'd be easy to
    # accidentally cause this assumption to fail as code is changed and
    # gems are added or updated.
    first = `RAILS_ENV=production rake middleware | grep '^use ' | head -1`
    first = first.chomp
    assert_equal 'use Rack::Cors', first
  end

  test 'CORS library middleware stack location check in test environment' do
    first = `RAILS_ENV=test rake middleware | grep '^use ' | head -1`
    first = first.chomp
    assert_equal 'use Rack::Cors', first
  end
end
