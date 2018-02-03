# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectStatTest < ActiveSupport::TestCase
  setup do
    # Normalize time in order to test timestamps
    travel_to Time.zone.parse('2015-03-01T12:00:00') do
      @project_stat = ProjectStat.create!
    end
  end

  # If you change files in test/fixtures/* you may need to change
  # the expected values.
  test 'project_stat matches expected values' do
    assert_equal 6, @project_stat.percent_ge_0
    assert_equal 4, @project_stat.percent_ge_25
    assert_equal 4, @project_stat.percent_ge_50
    assert_equal 4, @project_stat.percent_ge_75
    assert_equal 3, @project_stat.percent_ge_90
    assert_equal 3, @project_stat.percent_ge_100
    assert_equal 5, @project_stat.created_since_yesterday
    assert_equal 0, @project_stat.updated_since_yesterday
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.created_at.to_s
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.updated_at.to_s
    assert_equal 8, @project_stat.users
  end

  test 'count including fixtures' do
    assert_equal 3, ProjectStat.count
  end
end
