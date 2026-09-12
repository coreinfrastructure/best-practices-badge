# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Admin-only visibility into active login sessions (docs/login-session.md
# section 3): lets an admin see who is currently logged in, from where,
# and revoke suspicious sessions via rake login_sessions:revoke.
class LoginSessionsController < ApplicationController
  before_action :require_admin!, only: [:index]

  # Lists all active login sessions, most recently used first.
  # Supports `GET /login_sessions`.
  # @return [void]
  def index
    @pagy, @login_sessions = pagy(
      :offset, LoginSession.order(last_used_at: :desc).includes(:user)
    )
  end
end
