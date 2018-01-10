# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class CorsLibraryTest < ActiveSupport::TestCase
  test 'CORS library middleware stack location check in environments' do
    # Because of the way it works, Rack::Cors *must* be first in the Rack
    # middleware stack, as documented here: https://github.com/cyu/rack-cors
    # This test verifies this precondition, because it'd be easy to
    # accidentally cause this assumption to fail as code is changed and
    # gems are added or updated.
    # This is a slow test (we bring up a whole environment), so we
    # intentionally omit "development" from the list of tested environments.
    %w[production test].each do |environment|
      command = "RAILS_ENV=#{environment} rake middleware"
      result = IO.popen(command).readlines.grep(/^use /).first.chomp
      assert_equal 'use Rack::Cors', result
    end
  end
end
