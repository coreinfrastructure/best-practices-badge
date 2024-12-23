# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Specially test "in_development?" helper.

require 'test_helper'

class NotInDevelopmentTest < ActiveSupport::TestCase
  test 'The production system will say it is NOT in development' do
    ac = ApplicationController.new
    assert ac.in_development?
    assert_not ac.in_development?('true')
  end
end
