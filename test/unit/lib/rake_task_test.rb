# frozen_string_literal: true
require 'test_helper'

# rubocop:disable Metrics/ClassLength
class RakeTaskTest < ActiveSupport::TestCase

  test 'regression test for rake reminders' do
    assert_equal 1, Project.projects_to_remind.size
    result = system 'rake reminders >/dev/null'
    assert result
    assert_equal 0, Project.projects_to_remind.size
  end
end
