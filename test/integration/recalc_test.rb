# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class RecalcTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test 'Make sure recalc percentages only updates levels specified' do
    project = projects(:one)
    old_percentage = project.badge_percentage_1
    assert_equal 0, old_percentage, 'Old silver percentage wrong'
    # Update some columns without triggering percentage calculation
    # or change in updated_at
    assert_no_difference [
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_1',
      'Project.find(projects(:one).id).badge_percentage_2',
      'Project.find(projects(:one).id).updated_at'
    ] do
      project.update_column(:crypto_weaknesses_status, 3) # Met
      project.update_column(:crypto_weaknesses_justification, 'It is good')
      project.update_column(:warnings_strict_status, 3) # Met
      project.update_column(:warnings_strict_justification, 'It is good')
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
    project = projects(:one)
    old_percentage0 = project.badge_percentage_0
    old_percentage1 = project.badge_percentage_1
    assert_equal 1, old_percentage0, 'Old passing percentage wrong'
    assert_equal 0, old_percentage1, 'Old silver percentage wrong'
    # Update some columns without triggering percentage calculation
    # or change in updated_at
    assert_no_difference [
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_1',
      'Project.find(projects(:one).id).badge_percentage_2',
      'Project.find(projects(:one).id).updated_at'
    ] do
      project.update_column(:crypto_weaknesses_status, 3) # Met
      project.update_column(:crypto_weaknesses_justification, 'It is good')
      project.update_column(:warnings_strict_status, 3) # Met
      project.update_column(:warnings_strict_justification, 'It is good')
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
    assert_raises(ArgumentError) do
      Project.update_all_badge_percentages(['3'])
    end
  end

  # --- update_all_badge_percentages loss-column tests ---

  test 'update_all_badge_percentages sets unreported_badge_loss on metal loss' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    Project.update_all_badge_percentages(['0'])
    assert_equal Sections::BADGE_LEVEL_RANK['passing'],
                 Project.find(project.id).unreported_badge_loss
  end

  test 'update_all_badge_percentages sets unreported_baseline_badge_loss on baseline loss' do
    project = projects(:one)
    project.update_column(:badge_percentage_baseline_1, 100)
    Project.update_all_badge_percentages(['baseline-1'])
    assert_equal Sections::BADGE_LEVEL_RANK['baseline-1'],
                 Project.find(project.id).unreported_baseline_badge_loss
  end

  test 'update_all_badge_percentages does not set columns when notify_losses: false' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    Project.update_all_badge_percentages(['0'], notify_losses: false)
    assert_equal 0, Project.find(project.id).unreported_badge_loss
  end

  # --- send_loss_notifications tests ---

  test 'send_loss_notifications enqueues email and clears column' do
    project = projects(:one)
    project.update_column(:unreported_badge_loss, 1) # rank of 'passing'
    assert_enqueued_emails(1) do
      Project.send_loss_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_badge_loss
  end

  test 'send_loss_notifications enqueues baseline email and clears column' do
    project = projects(:one)
    project.update_column(:unreported_baseline_badge_loss, 1) # rank of 'baseline-1'
    assert_enqueued_emails(1) do
      Project.send_loss_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_baseline_badge_loss
  end

  test 'send_loss_notifications silently clears column when important_notifications false' do
    project = projects(:one)
    project.user.update_column(:important_notifications, false)
    project.update_column(:unreported_badge_loss, 1)
    assert_enqueued_emails(0) do
      Project.send_loss_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_badge_loss
  end

  test 'send_loss_notifications skips email if badge already regained' do
    # perfect_passing has tiered_percentage >= 100, so badge_level = 'passing'.
    # Setting unreported_badge_loss = 1 (passing) means the loss is no longer
    # current — the badge was regained — so no email should be sent.
    project = projects(:perfect_passing)
    project.update_column(:unreported_badge_loss, 1)
    assert_enqueued_emails(0) do
      Project.send_loss_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_badge_loss
  end

  test 'send_loss_notifications sets last_loss_sent_at' do
    project = projects(:one)
    project.update_column(:unreported_badge_loss, 1)
    assert_nil Project.find(project.id).last_loss_sent_at
    Project.send_loss_notifications
    assert_not_nil Project.find(project.id).last_loss_sent_at
  end

  # --- update_all_badge_warnings tests ---

  test 'update_all_badge_warnings sets unreported_badge_warning on metal loss' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    Project.update_all_badge_warnings(Criteria.keys,
                                      effective_date: Time.zone.today + 30)
    assert_equal Sections::BADGE_LEVEL_RANK['passing'],
                 Project.find(project.id).unreported_badge_warning
  end

  test 'update_all_badge_warnings sets badge_warning_effective_date' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    future_date = Time.zone.today + 30
    Project.update_all_badge_warnings(Criteria.keys,
                                      effective_date: future_date)
    assert_equal future_date,
                 Project.find(project.id).badge_warning_effective_date
  end

  test 'update_all_badge_warnings does not change badge_percentage_0 in DB' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    Project.update_all_badge_warnings(Criteria.keys,
                                      effective_date: Time.zone.today + 30)
    assert_equal 100, Project.find(project.id).badge_percentage_0
  end

  test 'update_all_badge_warnings sets unreported_baseline_badge_warning' do
    project = projects(:one)
    project.update_column(:badge_percentage_baseline_1, 100)
    Project.update_all_badge_warnings(['baseline-1'],
                                      effective_date: Time.zone.today + 30)
    assert_equal Sections::BADGE_LEVEL_RANK['baseline-1'],
                 Project.find(project.id).unreported_baseline_badge_warning
  end

  test 'update_all_badge_warnings with report: true prints project info' do
    project = projects(:one)
    project.update_column(:badge_percentage_0, 100)
    project.update_column(:tiered_percentage, 100)
    assert_output(/Project #{project.id}/) do
      Project.update_all_badge_warnings(Criteria.keys,
                                        effective_date: Time.zone.today + 30,
                                        report: true)
    end
    # Must not write warning columns in report mode
    assert_equal 0, Project.find(project.id).unreported_badge_warning
  end

  test 'update_all_badge_warnings report: true prints baseline info' do
    project = projects(:one)
    project.update_column(:badge_percentage_baseline_1, 100)
    assert_output(/\(baseline\)/) do
      Project.update_all_badge_warnings(['baseline-1'],
                                        effective_date: Time.zone.today + 30,
                                        report: true)
    end
    # Must not write warning columns in report mode
    assert_equal 0, Project.find(project.id).unreported_baseline_badge_warning
  end

  # --- send_warning_notifications tests ---

  test 'send_warning_notifications enqueues email and clears column' do
    project = projects(:one)
    project.update_column(:unreported_badge_warning, 1) # rank of 'passing'
    assert_enqueued_emails(1) do
      Project.send_warning_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_badge_warning
  end

  test 'send_warning_notifications enqueues baseline email and clears column' do
    project = projects(:one)
    project.update_column(:unreported_baseline_badge_warning, 1)
    assert_enqueued_emails(1) do
      Project.send_warning_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_baseline_badge_warning
  end

  test 'send_warning_notifications silently clears column when important_notifications false' do
    project = projects(:one)
    project.user.update_column(:important_notifications, false)
    project.update_column(:unreported_badge_warning, 1)
    assert_enqueued_emails(0) do
      Project.send_warning_notifications
    end
    assert_equal 0, Project.find(project.id).unreported_badge_warning
  end

  test 'send_warning_notifications sets last_warning_sent_at' do
    project = projects(:one)
    project.update_column(:unreported_badge_warning, 1)
    assert_nil Project.find(project.id).last_warning_sent_at
    Project.send_warning_notifications
    assert_not_nil Project.find(project.id).last_warning_sent_at
  end
end
# rubocop:enable Metrics/ClassLength
