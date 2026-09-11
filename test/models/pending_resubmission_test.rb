# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class PendingResubmissionModelTest < ActiveSupport::TestCase
  def build_pending(created_at:)
    pending = PendingResubmission.stash_for(
      resubmit_path: '/en/projects/1',
      resubmit_method: 'PATCH',
      params_json: { 'project[name]' => 'x' }.to_json,
      sensitive_fields_dropped: false
    )
    pending.update_columns(created_at: created_at)
    pending
  end

  test 'find_by_token round-trips a stashed row and rejects a blank token' do
    pending = build_pending(created_at: Time.now.utc)
    assert_equal pending, PendingResubmission.find_by_token(pending.raw_token)
    assert_nil PendingResubmission.find_by_token(nil)
    assert_nil PendingResubmission.find_by_token('')
  end

  # ,evaluation.md finding #4: purge_stale, not #show, is what eventually
  # removes an abandoned stash, so it needs its own boundary coverage the
  # way LoginSession.purge_stale already has (test/models/login_session_test.rb).
  test 'purge_stale deletes rows older than STALE_LIFETIME but keeps newer ones' do
    fresh = build_pending(created_at: PendingResubmission::STALE_LIFETIME.ago + 1.minute)
    stale = build_pending(created_at: PendingResubmission::STALE_LIFETIME.ago - 1.minute)

    assert_equal 1, PendingResubmission.purge_stale
    assert PendingResubmission.exists?(fresh.id)
    assert_not PendingResubmission.exists?(stale.id)
  end
end
