# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class AccountActivationsController < ApplicationController
  # Time in seconds after activating local account before login allowed.
  LOCAL_LOGIN_COOLOFF_TIME =
    Integer(ENV['LOCAL_LOGIN_COOLOFF_TIME'] || '3600', 10)

  # Show the activation confirmation page. We do NOT activate here so that
  # email clients that auto-fetch URLs cannot activate accounts on behalf of
  # users who never saw the email.
  def edit
    activation_params = params.permit(:email, :id)
    @token = activation_params[:id]
    @email = activation_params[:email]
    return if @token.present? && @email.present?

    flash[:danger] = t('account_activations.failed_activation')
    redirect_to root_url
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def update
    activation_params = params.permit(:email, :id)
    if activation_params[:email].blank? || activation_params[:id].blank?
      flash[:danger] = t('account_activations.link_invalid_or_used')
      return redirect_to login_path
    end
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
    else
      flash[:danger] = t('account_activations.link_invalid_or_used')
    end
    redirect_to login_path
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
