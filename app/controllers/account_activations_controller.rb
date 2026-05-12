# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class AccountActivationsController < ApplicationController
  # Time in seconds after activating local account before login allowed.
  LOCAL_LOGIN_COOLOFF_TIME =
    Integer(ENV['LOCAL_LOGIN_COOLOFF_TIME'] || '3600', 10)

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def edit
    # We use a GET request for one-click activation. This is safe because:
    # 1. The token is a single-use secret that is invalidated upon use.
    # 2. find_unactivated_by_valid_token uses constant-time comparison.
    # 3. email and token are filtered from Rails logs.
    # This does mean that if a user's email system (and/or email monitor)
    # auto-clicks on all incoming URLs, the user will automatically
    # approve and activate the account.
    activation_params = params.permit(:email, :id)
    user = User.find_unactivated_by_valid_token(
      activation_params[:email], activation_params[:id]
    )
    if user
      user.can_login_starting_at = Time.zone.now + LOCAL_LOGIN_COOLOFF_TIME
      user.activate # This saves our result
      flash[:success] = t('account_activations.activated') + ' ' +
                        t(
                          'account_activations.delay',
                          count: LOCAL_LOGIN_COOLOFF_TIME / 3600.0
                        )
      # We do *not* log in user. This reduces the number of paths that
      # automatically log in, and increases the likelihood
      # that a user's password manager will see the password.
      redirect_to login_path
    else
      flash[:danger] = t('account_activations.failed_activation')
      redirect_to root_url
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
