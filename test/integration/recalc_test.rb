# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class RecalcTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test 'Make sure recalc percentages only updates levels specified' do
    old_percentage = @project.badge_percentage_1
    assert old_percentage.zero?
    # Update some columns without triggering percentage calculation
    # or change in updated_at
    assert_no_difference [
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_1',
      'Project.find(projects(:one).id).badge_percentage_2',
      'Project.find(projects(:one).id).updated_at'
    ] do
      @project.update_column(:crypto_weaknesses_status, 'Met')
      @project.update_column(:crypto_weaknesses_justification, 'It is good')
      @project.update_column(:warnings_strict_status, 'Met')
      @project.update_column(:warnings_strict_justification, 'It is good')
    end
    # Run the update task, make sure updated_at and others don't change
    assert_no_difference [
      'Project.find(projects(:one).id).updated_at',
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_2'
    ] do
      Project.update_all_badge_percentages(['1'])
    end
    # Check the badge percentage changed
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage_1,
      old_percentage
    )
  end

  # rubocop:disable Metrics/BlockLength
  test 'Make sure recalc percentages only updates levels affected' do
    old_percentage0 = @project.badge_percentage_0
    old_percentage1 = @project.badge_percentage_1
    assert old_percentage0.zero?, 'Old passing percentage is supposed to be 0'
    assert old_percentage1.zero?, 'Old silver percentage is supposed to be 0'
    # Update some columns without triggering percentage calculation
    # or change in updated_at
    assert_no_difference [
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_1',
      'Project.find(projects(:one).id).badge_percentage_2',
      'Project.find(projects(:one).id).updated_at'
    ] do
      @project.update_column(:crypto_weaknesses_status, 'Met')
      @project.update_column(:crypto_weaknesses_justification, 'It is good')
      @project.update_column(:warnings_strict_status, 'Met')
      @project.update_column(:warnings_strict_justification, 'It is good')
    end
    # Run the update task, make sure updated_at and others don't change
    assert_no_difference [
      'Project.find(projects(:one).id).updated_at',
      'Project.find(projects(:one).id).badge_percentage_2'
    ] do
      # Level 2 does not depend on these keys
      # so it's percentage should not change
      Project.update_all_badge_percentages(Criteria.keys)
    end
    # Check the badge percentage changed
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage_0,
      old_percentage0,
      'passing badge percentage is supposed to change'
    )
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage_1,
      old_percentage1,
      'silver badge percentage is supposed to change'
    )
  end
  # rubocop:enable Metrics/BlockLength

  test 'Raises TypeError' do
    assert_raises(TypeError) { Project.update_all_badge_percentages('1') }
  end

  test 'Raises ArgumentError' do
    assert_raises(ArgumentError) { Project.update_all_badge_percentages(['3']) }
  end
end
