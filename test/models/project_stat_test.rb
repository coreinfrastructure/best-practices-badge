# frozen_string_literal: true

require 'test_helper'

class ProjectStatTest < ActiveSupport::TestCase
  def setup
    # Temporary fix for issue #397
    # This deletes an extra record introduced by VCR with some test seeds
    # Repeated here because this runs before test_helper setup
    unless Project.count == 4
      p "Deleting extra project. #{Project.count} projects in #{method_name}"
      Project.where(name: 'Core Infrastructure Initiative Best Practices Badge')
             .destroy_all
    end

    # Normalize time in order to test timestamps
    travel_to Time.zone.parse('2015-03-01T12:00:00') do
      @project_stat = ProjectStat.create!
    end
  end

  test 'project_stat matches expect values' do
    assert_equal 4, @project_stat.percent_ge_0
    assert_equal 2, @project_stat.percent_ge_25
    assert_equal 2, @project_stat.percent_ge_50
    assert_equal 2, @project_stat.percent_ge_75
    assert_equal 1, @project_stat.percent_ge_90
    assert_equal 1, @project_stat.percent_ge_100
    assert_equal 3, @project_stat.created_since_yesterday
    assert_equal 0, @project_stat.updated_since_yesterday
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.created_at.to_s
    assert_equal '2015-03-01 12:00:00 UTC', @project_stat.updated_at.to_s
  end

  test 'count including fixtures' do
    assert_equal 3, ProjectStat.count
  end
end
