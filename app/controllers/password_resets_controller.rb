# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PasswordResetsController < ApplicationController
  before_action :obtain_user, only: %i[edit update]
  before_action :valid_user, only: %i[edit update]
  before_action :check_expiration, only: %i[edit update]

  # Show "Forgot password" screen, a form that lets the user
  # enter an email address to begin the password reset process.
  # GET (/:locale)/password_resets/new(.:format)
  def new; end

  # User has entered an email address for a password reset.
  # If the email address is a valid local account, create a reset digest
  # and email the reset digest value to the account.  The "reset digest"
  # is like a very temporary password.
  # POST (/:locale)/password_resets(.:format)
  def create
    @user = User.find_by(email: params[:password_reset][:email])
    if @user
      reset_password(@user)
    else
      flash.now[:danger] = t('password_resets.email_not_found')
      render 'new'
    end
  end

  # Show "Reset password" screen, a form that lets the user
  # double-enter a new password.  Via valid_user
  # we require an "id" (the reset_digest value) and matching email address
  # (the email address would be in the query string).
  # We won't even show this screen if the user doesn't have a valid
  # reset_digest + email pair; that's not necessary for security, but there's
  # no point in showing this screen if the action will be rejected later.
  # An example of a URL that gets here would be: http://localhost:3000/
  # password_resets/f_xAqrghtIkANa0HS_B0TA/edit?email=dwheele4%40gmu.edu
  # GET (/:locale)/password_resets/:id/edit(.:format)
  def edit; end

  # If authorized, change user password.
  # The valid_user check ensures that we can only run this if the
  # user knows (1) the email address and (2) the matching reset_digest
  # we just sent to that email address.
  # The "user" model will require that the new password is confirmed
  # and meets various password requirements (e.g., has minimum length and
  # isn't well-known).
  # PATCH (/:locale)/password_resets/:id(.:format)
  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, t('password_resets.password_empty'))
      render 'edit'
    elsif @user.update_attributes(user_params)
      log_in @user
      flash[:success] = t('password_resets.password_reset')
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

  def reset_password(user)
    if user.provider == 'local'
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = t('password_resets.instructions_sent')
      redirect_to root_url
    else
      flash[:danger] = t('password_resets.cant_reset_nonlocal')
      redirect_to login_url
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def obtain_user
    @user = User.find_by(email: params[:email])
  end

  # Confirms a valid user.  The "id" in this case is *NOT* the
  # database primary key (e.g., "42"), but the claimed reset_digest value
  # provided by the untrusted user.  We compare this provided reset_digest
  # with the *actual* reset_digest stored on the user obtained via
  # the email lookup - if they are the same, then we have a valid user
  # who knows *both* the email address AND the reset_digest we just sent.
  def valid_user
    unless @user&.activated? &&
           @user&.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  # Checks expiration of reset token.
  def check_expiration
    return unless @user.password_reset_expired?
    flash[:danger] = t('password_resets.reset_expired')
    redirect_to new_password_reset_url
  end
end
