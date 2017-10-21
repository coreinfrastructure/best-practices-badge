# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop: disable Metrics/ClassLength
class UsersController < ApplicationController
  before_action :require_admin,  only: %i[destroy]
  before_action :logged_in_user, only: %i[edit update index]
  before_action :correct_user,   only: %i[edit update]
  include SessionsHelper

  def new
    @user = User.new
  end

  def index
    @users = User.all.paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @projects = select_needed(@user.projects).paginate(page: params[:page])
    return unless @user == current_user && @user.provider == 'github'
    @edit_projects =
      select_needed(Project.where(repo_url: github_user_projects)) - @projects
  end

  # rubocop: disable Metrics/MethodLength
  def create
    @user = User.find_by(email: user_params[:email])
    if @user
      redirect_existing
    else
      @user = User.new(user_params)
      @user.provider = 'local'
      @user.preferred_locale = I18n.locale.to_s
      if @user.save
        send_activation
      else
        render 'new'
      end
    end
  end
  # rubocop: enable Metrics/MethodLength

  def edit
    @user = User.find(params[:id])
    # Force redirect if current_user cannot edit.  Otherwise, the process
    # of displaying the edit fields (with their defaults) could cause an
    # unauthorized exposure of an email address.
    redirect_to @user unless current_user_can_edit(@user)
  end

  # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # If user changed his own locale, switch to it.  It's possible for an
      # *admin* to change someone else's locale, in that case leave it alone.
      if current_user == @user && user_params[:preferred_locale]
        I18n.locale = user_params[:preferred_locale].to_sym
      end
      # Email user on every change.  That way, if the user did *not* initiate
      # the change (e.g., because it's by an admin or by someone who broke
      # into their account), the user will know about it.
      UserMailer.user_update(@user, @user.previous_changes).deliver_now
      flash[:success] = t('.profile_updated')
      locale_prefix = I18n.locale == :en ? '' : '/' + I18n.locale.to_s
      redirect_to "#{locale_prefix}/users/#{@user.id}"
    else
      render 'edit'
    end
  end
  # rubocop: enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
  def destroy
    # We don't do a lot of checking because only admins can run this,
    # but we'll try to prevent some disasters.
    id_to_delete = params[:id]
    user_to_delete = User.find(id_to_delete) # Exception raised if not found
    if current_user.id == user_to_delete.id
      flash[:danger] = t('.cannot_delete_self')
    else
      # Admin acquires ownership of remaining projects, if any,
      # so projects always have an owner (maintain invariant).
      # rubocop: disable Rails/SkipsModelValidations
      Project.where('user_id = ?', id_to_delete)
             .update_all(user_id: current_user.id)
      # rubocop: enable Rails/SkipsModelValidations
      user_to_delete.destroy!
      flash[:success] = t('.user_deleted')
    end
    redirect_to users_url
  end
  # rubocop: enable Metrics/MethodLength, Metrics/AbcSize

  def redirect_existing
    if @user.activated
      flash[:info] = t('users.redirect_existing')
      redirect_to login_url
    else
      regenerate_activation_digest
      send_activation
    end
  end

  def send_activation
    @user.send_activation_email
    flash[:info] = t('users.new_activation_link_created')
    redirect_to root_url
  end

  private

  def user_params
    user_params = params.require(:user).permit(
      :provider, :uid, :name, :email, :password,
      :password_confirmation, :preferred_locale
    )
    # Remove the password and password confirmation keys for empty values
    user_params.delete(:password) if user_params[:password].blank?
    user_params.delete(:password_confirmation) if
      user_params[:password_confirmation].blank?
    user_params
  end

  def require_admin
    redirect_to root_url unless current_user&.admin?
  end

  # Confirms a logged-in user.
  def logged_in_user
    return if logged_in?
    flash[:danger] = t('users.please_log_in')
    redirect_to login_url
  end

  # Return true if current_user can edit account 'user'
  def current_user_can_edit(user)
    return false unless current_user
    user == current_user || current_user.admin?
  end

  # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user_can_edit(@user)
  end

  def regenerate_activation_digest
    @user.activation_token = User.new_token
    @user.activation_digest = User.digest(@user.activation_token)
    @user.save!(touch: false)
  end

  # If we're sending an HTML project table, select only the fields needed.
  # This significantly reduces memory allocations.
  def select_needed(dataset)
    return dataset unless request.format.symbol == :html
    dataset.select(ProjectsController::HTML_INDEX_FIELDS)
  end
end
# rubocop: enable Metrics/ClassLength
