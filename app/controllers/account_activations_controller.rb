# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class AccountActivationsController < ApplicationController
  # Time in seconds after activating local account before login allowed.
  LOCAL_LOGIN_COOLOFF_TIME = (ENV['LOCAL_LOGIN_COOLOFF_TIME'] || 3600).to_i

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      user.can_login_starting_at = Time.zone.now + LOCAL_LOGIN_COOLOFF_TIME
      user.save!
      flash[:success] = t('account_activations.activated') + ' ' +
                        t(
                          'account_activations.delay',
                          count: LOCAL_LOGIN_COOLOFF_TIME
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
