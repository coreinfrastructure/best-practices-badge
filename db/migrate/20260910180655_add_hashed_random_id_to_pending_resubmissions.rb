# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Step 18 (docs/login-session-18.md): a pending_resubmissions row was
# previously looked up by its own guessable, sequential primary key,
# safe only because that id never appeared anywhere web-reachable except
# this browser's own encrypted session cookie. A SECRET_KEY_BASE leak
# breaks that assumption by itself: it lets an attacker forge a cookie
# naming any row's id directly, no other secret needed. hashed_random_id
# gives this table the same keyed-HMAC protection login_sessions already
# has: the value stored in the cookie is now a random token, never the
# row's id, and only its HMAC digest (keyed by PENDING_RESUBMISSION_HMAC_KEY,
# a secret independent of SECRET_KEY_BASE) is stored here.
class AddHashedRandomIdToPendingResubmissions < ActiveRecord::Migration[8.1]
  def up
    # Any existing row predates this column: its session cookie encodes
    # an :id no code will look up anymore once this lands, so it's
    # already orphaned (and single-use/short-lived by design regardless).
    # Clear rather than backfill a value nothing could have produced.
    execute 'DELETE FROM pending_resubmissions'
    add_column :pending_resubmissions, :hashed_random_id, :string, null: false,
               comment: "HMAC-SHA256 of the raw random token in the " \
                        "browser's cookie; never the raw token itself"
    add_index :pending_resubmissions, :hashed_random_id, unique: true
  end

  def down
    remove_index :pending_resubmissions, :hashed_random_id
    remove_column :pending_resubmissions, :hashed_random_id
  end
end
