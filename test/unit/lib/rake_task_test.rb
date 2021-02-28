# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class RakeTaskTest < ActiveSupport::TestCase
  test 'regression test for rake reminders' do
    assert_equal 1, Project.projects_to_remind.size
    result = system 'rake reminders >/dev/null'
    assert result
    assert_equal 0, Project.projects_to_remind.size
  end
end
