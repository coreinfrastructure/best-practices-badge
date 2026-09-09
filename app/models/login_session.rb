# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# One row per active login (docs/login-session.md section 3). This has
# nothing to do with Rack's own session mechanism (the "session_id" key
# ApplicationController::SESSION_BOOKKEEPING_KEYS tracks); it's our own
# server-side record of one login, keyed from session[:login_session_id],
# a separate random id we mint ourselves. See design doc section 6.6 for
# why the two are deliberately kept distinct.
class LoginSession < ApplicationRecord
  extend HexKeyManagement

  belongs_to :user

  DIGITS_OF_SESSION_ID_HMAC_KEY = 256 / 8 * 2 # 256-bit HMAC key in hex

  # For tests. '3' is unused by User's two existing keys ('1', '2'), so a
  # copy-paste error between the three is easy to spot.
  TEST_SESSION_ID_HMAC_KEY = '3' * DIGITS_OF_SESSION_ID_HMAC_KEY

  # The raw session id, set only right after #create_for and never
  # persisted (there is no session_id column, only session_id_digest).
  # Exists so a caller that just created a row (log_in,
  # try_remember_token_login) gets both the row and the cookie value from
  # one call, instead of creating a row and then querying it back.
  attr_reader :raw_session_id

  # Returns the hex key for the session id HMAC. Same test/production
  # split as User.email_blind_index_key_hex.
  def self.session_id_hmac_key_hex(env_test: Rails.env.test?)
    hex_key_for(env_var: 'SESSION_ID_HMAC_KEY',
                test_value: TEST_SESSION_ID_HMAC_KEY, env_test: env_test)
  end
  private_class_method :session_id_hmac_key_hex

  def self.session_id_hmac_key
    # Hex string -> raw key bytes, matching how EMAIL_BLIND_INDEX_KEY is
    # unpacked in app/models/user.rb. Skipping this conversion wouldn't
    # fail loudly: the hex string itself still works as *some* HMAC key,
    # just with less entropy than intended, silently, with no error.
    [session_id_hmac_key_hex].pack('H*')
  end
  private_class_method :session_id_hmac_key

  def self.digest(session_id)
    OpenSSL::HMAC.hexdigest('SHA256', session_id_hmac_key, session_id)
  end

  # @param user [User] the user this session belongs to
  # @param ip_address [String] the client IP address at login
  # @param user_agent [String] the client's User-Agent header
  # @return [LoginSession] the created row; #raw_session_id holds the
  #   raw session id to store in the client's cookie
  def self.create_for(user, ip_address:, user_agent:)
    session_id = User.new_token # reuse, don't reinvent (design doc section 5)
    login_session = create!(
      user: user,
      session_id_digest: digest(session_id),
      last_used_at: Time.now.utc,
      ip_address: ip_address,
      user_agent: user_agent
    )
    login_session.instance_variable_set(:@raw_session_id, session_id)
    login_session
  end

  # @param session_id [String, nil] the raw session id from the cookie
  # @return [LoginSession, nil] the matching row, or nil if not found
  def self.find_by_session_id(session_id)
    return if session_id.blank?

    find_by(session_id_digest: digest(session_id))
  end

  def idle_expired?
    last_used_at < SessionsHelper::SESSION_TTL.ago.utc
  end

  def absolutely_expired?
    created_at < SessionsHelper::ABSOLUTE_SESSION_AGE.ago.utc
  end
end
