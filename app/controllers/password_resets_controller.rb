# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PasswordResetsController < ApplicationController
  before_action :obtain_user, only: %i[edit update]
  before_action :require_valid_user, only: %i[edit update]
  before_action :require_unexpired_reset, only: %i[edit update]

  def new; end

  def create
    @user = User.find_by(email: nested_params(:password_reset, :email))
    if @user
      # NOTE: We send the password reset to the email address originally
      # created by the *original* user, and *not* to the requester
      # (who may be attacking the original user's account). This prevents
      # attacks where the finding system is "overly generous" and matches
      # the "wrong" email address (e.g., exploiting dotless i). See:
      # https://eng.getwisdom.io/hacking-github-with-unicode-dotless-i/
      reset_password(@user)
    else
      flash.now[:danger] = t('password_resets.email_not_found')
      render 'new'
    end
  end

  def edit; end

  def update
    new_password = nested_params(:user, :password)
    if new_password.nil? || new_password == ''
      @user.errors.add(:password, t('password_resets.password_empty'))
      render 'edit'
    elsif @user.update(user_params)
      flash[:success] = t('password_resets.password_reset')
      redirect_to login_path
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

  # Confirms a valid user.
  def require_valid_user
    unless @user&.activated? &&
           @user&.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  # Checks expiration of reset token.
  def require_unexpired_reset
    return unless @user.password_reset_expired?

    flash[:danger] = t('password_resets.reset_expired')
    redirect_to new_password_reset_url
  end

  # Return params[outer][inner] but handle nil gracefully by returning nil.
  # This makes it easier to avoid nil dereferences.
  def nested_params(outer, inner)
    return if params.nil? || !params.key?(outer)
    return unless params[outer].key?(inner)

    params[outer][inner]
  end
end
