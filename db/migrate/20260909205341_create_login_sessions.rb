# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# One row per active login (design doc docs/login-session.md section 3).
# session_id_digest never stores the raw session id, only its HMAC, so a
# database leak alone can't be used to forge or replay a session
# (docs/login-session-implementation.md section 1).
#
# last_used_at and created_at each get their own index, not the
# t.timestamps default: both are queried directly (the admin listing
# orders by last_used_at; the daily cleanup filters on last_used_at OR
# created_at), and this table's growth is bounded only by general per-IP
# throttles, not signup-level friction, so the cleanup query that keeps
# it bounded must not itself be a full-table scan.
class CreateLoginSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :login_sessions,
                 comment: 'One row per active login. Not Rack\'s own ' \
                          'session bookkeeping; see docs/login-session.md.' do |t|
      t.string :session_id_digest, null: false,
               comment: 'HMAC-SHA256 of the raw session id; never the ' \
                        'raw id itself'
      t.bigint :user_id, null: false, comment: 'The user this login belongs to'
      t.datetime :last_used_at, null: false,
                 comment: 'Bumped at most once per RESET_SESSION_TIMER; ' \
                          'idle sessions past SESSION_TTL are expired'
      t.string :ip_address, comment: 'Client IP address at login'
      t.text :user_agent, comment: 'Client User-Agent header at login; ' \
                                   'not size-limited to 255 chars like the ' \
                                   'default varchar column'
      t.timestamps
    end
    add_index :login_sessions, :session_id_digest, unique: true
    add_index :login_sessions, :user_id
    add_index :login_sessions, :last_used_at
    add_index :login_sessions, :created_at
    add_foreign_key :login_sessions, :users
  end
end
