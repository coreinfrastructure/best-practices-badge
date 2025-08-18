# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Handles user authentication and session management.
# Supports both OAuth (GitHub) and local email/password authentication.
# Manages session creation, destruction, and security measures like
# session fixation protection.
#
class SessionsController < ApplicationController
  include SessionsHelper

  # Do *NOT* redirect session creation, that will cause complicated failures
  # because we don't really want the locale.
  skip_before_action :redir_missing_locale, only: :create

  # Display login form or redirect if already logged in.
  # Supports `GET /login`.
  # @return [void]
  def new
    if logged_in?
      flash[:success] = t('sessions.already_logged_in')
      redirect_to root_url
    else
      use_secure_headers_override(:allow_github_form_action)
      store_location_and_locale
    end
  end

  # Process login attempt via OAuth or local authentication.
  # Handles session fixation protection and various authentication methods.
  # Supports `POST /login`.
  # @return [void]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create
    counter_fixation # Counter session fixation (but save forwarding url)
    if Rails.application.config.deny_login
      flash.now[:danger] = t('sessions.login_disabled')
      render 'new', status: :forbidden
    elsif request.env['omniauth.auth'].present?
      omniauth_login
    elsif params[:session][:provider] == 'local'
      local_login
    else
      flash.now[:danger] = t('sessions.incorrect_login_info')
      render 'new'
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Log out current user and redirect to home page.
  # Supports `DELETE /logout`.
  # @return [void]
  def destroy
    log_out if logged_in?
    flash[:success] = t('sessions.signed_out')
    redirect_to root_url
  end

  private

  # Performs post-login setup for authenticated users.
  # Records login time, displays welcome message, and redirects appropriately.
  #
  # @param user [User] The authenticated user
  # @return [void]
  def successful_login(user)
    log_in user
    redirect_back_or root_url

    # Report last login time (this can help users detect problems)
    last_login = user.last_login_at
    last_login = t('sessions.no_login_time') if last_login.blank?
    flash[:success] = t('sessions.signed_in', last_login_at: last_login)

    # Record last_login_at time.  We use update_columns because
    # it works even if we don't have the correct email decryption keys,
    # and so it won't change updated_at (so updated_at becomes more useful).
    # We don't need the model validations, we're just setting a timestamp.
    # rubocop: disable Rails/SkipsModelValidations
    user.update_columns(last_login_at: Time.now.utc)
    # rubocop: enable Rails/SkipsModelValidations
  end

  # Protects against session fixation while preserving forwarding URL.
  # Resets the session but maintains the intended redirect destination.
  # @return [void]
  def counter_fixation
    ref_url = session[:forwarding_url] # Save forwarding url
    I18n.locale = session[:locale]
    reset_session # Counter session fixation
    session[:forwarding_url] = ref_url # Reload forwarding url
  end

  # Handles local email/password authentication.
  # @return [void]
  def local_login
    user = User.authenticate_local_user(
      params[:session][:email],
      params[:session][:password]
    )

    if user
      local_login_procedure(user)
    else
      flash.now[:danger] = t('sessions.invalid_combo')
      render 'new'
    end
  end

  # Handles OAuth authentication via GitHub.
  # Creates or finds user account and establishes session.
  # @return [void]
  def omniauth_login
    auth = request.env['omniauth.auth']
    user = User.find_by(provider: auth['provider'], uid: auth['uid']) ||
           User.create_with_omniauth(auth)
    session[:user_token] = auth['credentials']['token']
    session[:github_name] = auth['info']['nickname']
    user.name ||= user.nickname

    # TEMPORARY DEBUGGING
    Rails.logger.debug "DEBUG OAuth: About to login user #{user.id}"
    Rails.logger.debug "DEBUG OAuth: Session before: #{session.inspect}"

    successful_login(user)

    # TEMPORARY DEBUGGING
    Rails.logger.debug "DEBUG OAuth: Session after successful_login:
  #{session.inspect}"
    Rails.logger.debug "DEBUG OAuth: logged_in? = #{logged_in?}"
    Rails.logger.debug "DEBUG OAuth: current_user = #{current_user&.id}"
  end

  # Validates account status and processes local login.
  # Checks for account activation, login restrictions, and remember-me option.
  #
  # @param user [User] The user attempting to log in
  # @return [void]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def local_login_procedure(user)
    if !user.activated?
      flash[:warning] = t('sessions.not_activated')
      redirect_to root_url
    elsif !user.login_allowed_now?
      flash.now[:danger] = t('sessions.cannot_login_yet')
      render 'new', status: :forbidden
    else
      successful_login(user)
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      # Support a special make_old testing parameter in non-production.
      if !Rails.env.production? && params[:make_old] == 'true'
        session[:time_last_used] = 1000.days.ago
        session[:make_old] = true
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
