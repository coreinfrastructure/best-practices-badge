# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :obtain_user, only: %i[edit update]
  before_action :valid_user, only: %i[edit update]
  before_action :check_expiration, only: %i[edit update]

  def new; end

  def create
    @user = User.find_by(email: params[:password_reset][:email])
    if @user
      reset_password(@user)
    else
      flash.now[:danger] = t('password_resets.email_not_found')
      render 'new'
    end
  end

  def edit; end

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

  # Confirms a valid user.
  def valid_user
    unless @user && @user.activated? &&
           @user.authenticated?(:reset, params[:id])
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
