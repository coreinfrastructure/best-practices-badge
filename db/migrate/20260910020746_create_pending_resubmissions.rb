# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# One row per stashed form submission from a logged-out submitter who is
# being sent to re-authenticate (design doc
# docs/login-session-implementation.md section 15). Looked up only by its
# own primary key, read only from session[:pending_resubmission_id]; no
# externally suppliable identifier exists for this row, so there is
# nothing for an attacker to construct, share, or mismatch. No user_id or
# foreign key: a row here exists precisely because the submitter isn't
# authenticated yet.
class CreatePendingResubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_resubmissions,
                 comment: 'A stashed form submission awaiting re-login; ' \
                          'see docs/login-session-implementation.md section 15.' do |t|
      t.string :resubmit_path, null: false,
               comment: 'Path to resubmit the stashed params to'
      t.string :resubmit_method, null: false,
               comment: 'HTTP method to resubmit with (e.g. PATCH)'
      t.text :params_json, null: false,
             comment: 'Stashed params as JSON, sensitive fields excluded'
      t.boolean :sensitive_fields_dropped, null: false, default: false,
                comment: 'True if a password/email field was excluded from params_json'
      t.timestamps
    end
    add_index :pending_resubmissions, :created_at
  end
end
