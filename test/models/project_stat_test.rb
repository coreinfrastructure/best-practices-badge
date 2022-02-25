# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
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
    assert_equal 7, @project_stat.percent_ge_0
    assert_equal 4, @project_stat.percent_ge_25
    assert_equal 4, @project_stat.percent_ge_50
    assert_equal 4, @project_stat.percent_ge_75
    assert_equal 3, @project_stat.percent_ge_90
    assert_equal 3, @project_stat.percent_ge_100
    assert_equal 6, @project_stat.created_since_yesterday
    assert_equal 0, @project_stat.updated_since_yesterday
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.created_at.to_s
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.updated_at.to_s
    assert_equal 9, @project_stat.users
  end

  test 'count including fixtures' do
    # This includes the statistic created during setup
    assert_equal 9, ProjectStat.count
  end

  test 'ProjectStat.percent_field_name() works correctly' do
    assert_equal 'percent_ge_0', ProjectStat.percent_field_name(0, 0)
    assert_equal 'percent_ge_90', ProjectStat.percent_field_name(0, 90)
    assert_equal 'percent_1_ge_90', ProjectStat.percent_field_name(1, 90)
    assert_equal 'percent_2_ge_100', ProjectStat.percent_field_name(2, 100)
  end

  test 'ProjectStat.percent_field_description() works correctly' do
    I18n.with_locale(:en) do
      assert_equal 'Total Projects',
                   ProjectStat.percent_field_description(0, 0)
      assert_equal 'Total Projects',
                   ProjectStat.percent_field_description('0', 0)
      assert_equal 'Passing Projects',
                   ProjectStat.percent_field_description(0, 100)
      assert_equal 'Passing Projects',
                   ProjectStat.percent_field_description('0', 100)
      assert_equal 'Silver Projects',
                   ProjectStat.percent_field_description(1, 100)
      assert_equal 'Gold Projects',
                   ProjectStat.percent_field_description(2, 100)
      assert_equal 'Passing Projects, 50%+ to Silver',
                   ProjectStat.percent_field_description(1, 50)
      assert_equal 'Silver Projects, 90%+ to Gold',
                   ProjectStat.percent_field_description(2, 90)
      assert_equal 'Silver Projects, 90%+ to Gold',
                   ProjectStat.percent_field_description('2', 90)
    end
  end
end
