# frozen_string_literal: true

require 'test_helper'

class RecalcTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test 'Recalc percentages' do
    # Check starting badge_percentage is zero, as expected
    old_percentage = Project.find(projects(:one).id).badge_percentage
    assert old_percentage.zero?
    # Update some columns without triggering percentage calculation
    # or change in updated_at
    assert_no_difference(
      'Project.find(projects(:one).id).badge_percentage',
      'Project.find(projects(:one).id).updated_at'
    ) do
      @project.update_column(:homepage_url_status, 'Met')
      @project.update_column(:description_good_status, 'Met')
    end
    # Run the update task, make sure updated_at doesnt change
    assert_no_difference 'Project.find(projects(:one).id).updated_at' do
      Project.update_all_badge_percentages
    end
    # Check the badge percentage changed
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage,
      old_percentage
    )
  end
end
