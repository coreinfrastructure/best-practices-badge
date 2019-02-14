# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop: disable Metrics/ClassLength
class UsersController < ApplicationController
  # Note: If a "before" filter renders or redirects, the action will not run,
  # and other additional filters scheduled to run after it are cancelled.
  # See: http://guides.rubyonrails.org/action_controller_overview.html
  # Require being logged in for "index" to slightly discourage enumeration
  before_action :redir_unless_logged_in, only: %i[edit update destroy index]
  before_action :redir_unless_current_user_can_edit,
                only: %i[edit update destroy]
  before_action :enable_maximum_privacy_headers
  include SessionsHelper

  def new
    @user = User.new
  end

  def index
    @users = User.all.paginate(page: params[:page])
  end

  # rubocop: disable Metrics/AbcSize
  def show
    @user = User.find(params[:id])
    respond_to :html, :json

    # Use "select_needed" to minimize the fields we extract
    @projects = select_needed(@user.projects).paginate(page: params[:page])

    # Don't bother paginating, we typically don't have that many and the
    # interface would be confusing.
    @projects_additional_rights =
      select_needed(Project.joins(:additional_rights)
        .where('additional_rights.user_id = ?', @user.id))

    # *Separately* list edit_projects from projects_additional_rights.
    # Jason Dossett thinks they should be combined, but David A. Wheeler
    # thinks these are important to keep separate because how to *change*
    # what is in these lists is radically different.
    return unless @user == current_user && @user.provider == 'github'

    @edit_projects =
      select_needed(Project.where(repo_url: github_user_projects)) - @projects
  end
  # rubocop: enable Metrics/AbcSize

  # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
  def create
    if Rails.application.config.deny_login
      flash.now[:danger] = t('sessions.login_disabled')
      render 'new', status: :forbidden
      return
    end
    @user = User.find_by(email: user_params[:email])
    if @user
      redirect_existing
    else
      @user = User.new(user_params)
      @user.provider = 'local'
      @user.preferred_locale = I18n.locale.to_s
      @user.use_gravatar = @user.gravatar_exists # we know this is local
      if @user.save
        send_activation
      else
        render 'new'
      end
    end
  end
  # rubocop: enable Metrics/MethodLength, Metrics/AbcSize

  def edit
    @user = User.find(params[:id])
    # Force redirect if current_user cannot edit.  Otherwise, the process
    # of displaying the edit fields (with their defaults) could cause an
    # unauthorized exposure of an email address.
    redirect_to @user unless current_user_can_edit(@user)
  end

  # Produce a cleaned-up hash of changes.
  # The key is the field that was changed, the value is [old, new]
  # We must cleanup, because password_digest stores changes even when
  # old and new have the same value (so we must remove it).
  # In addition, because email values are encrypted, we have to separately
  # report the old and new values if they changed.
  def cleanup_changes(changeset, old_email, new_email)
    result = {}
    changeset.each do |key, change|
      # Only consider "change" if it is in the expected form [old, new]
      if change.is_a?(Array) && change.length == 2
        result[key] = change if change[0] != change[1]
      end
    end
    result['email'] = [old_email, new_email] unless old_email == new_email
    result
  end

  # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
  def update
    @user = User.find(params[:id])
    old_email = @user&.email_if_decryptable
    @user.assign_attributes(user_params)
    changes = cleanup_changes(
      @user.changes, old_email, @user.email_if_decryptable
    )
    if @user.save
      # If user changed his own locale, switch to it.  It's possible for an
      # *admin* to change someone else's locale, in that case leave it alone.
      if current_user == @user && user_params[:preferred_locale]
        I18n.locale = user_params[:preferred_locale].to_sym
      end
      # Email user on every change.  That way, if the user did *not* initiate
      # the change (e.g., because it's by an admin or by someone who broke
      # into their account), the user will know about it.
      UserMailer.user_update(@user, changes).deliver_now
      @user.use_gravatar = @user.gravatar_exists if @user.provider == 'local'
      flash[:success] = t('.profile_updated')
      locale_prefix = '/' + I18n.locale.to_s
      redirect_to "#{locale_prefix}/users/#{@user.id}"
    else
      render 'edit'
    end
  end
  # rubocop: enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop: disable Metrics/MethodLength
  def destroy
    id_to_delete = params[:id]
    user_to_delete = User.find(id_to_delete) # Exception raised if not found
    # Nest transaction to be *certain* we include all in the transaction
    Project.transaction do
      User.transaction do
        if Project.exists?(user_id: id_to_delete)
          flash[:danger] = t('.cannot_delete_user_with_projects')
        else
          # Use destroy! - raises exception on (unexpected) failure, and auto-
          # removes associated ApplicationRecords via the has_many association.
          # There may be ApplicationRecords on this user, because the user
          # cannot necessarily control the rights granted to him by others.
          user_to_delete.destroy!
          flash[:success] = t('.user_deleted')
          redirect_to root_path
        end
      end
    end
  end
  # rubocop: Metrics/MethodLength

  def redirect_existing
    if @user.activated
      flash[:info] = t('users.redirect_existing')
      redirect_to login_path
    else
      regenerate_activation_digest
      send_activation
    end
  end

  def send_activation
    @user.send_activation_email
    flash[:info] = t('users.new_activation_link_created')
    redirect_to root_path
  end

  private

  def enable_maximum_privacy_headers
    # Harden the response by maximizing HTTP headers of user data
    # for privacy. We do this by inhibiting indexing and caching.
    # Our primary goal is to ensure that we maintain the privacy of
    # private data.  However, we also want to be prepared so that
    # if there *is* a breach, we reduce its impact.
    # These lines instruct others to disable indexing and caching of
    # user data, so that if private data is inadvertantly released,
    # it is much less likely to be easily available to others via
    # web-crawled data (such as from search engines) or via caches.
    # The goal is to make it harder for adversaries to get leaked data.
    # We do this as HTTP headers, so it applies to anything (HTML, JSON, etc.)
    response.set_header('X-Robots-Tag', 'noindex')
    response.set_header('Cache-Control', 'no-cache, no-store, must-revalidate')
  end

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

  # Confirms a logged-in user.
  def redir_unless_logged_in
    return if logged_in?

    flash[:danger] = t('users.please_log_in')
    redirect_to login_path
  end

  # Return true if current_user can edit account 'user'
  def current_user_can_edit(user)
    return false unless current_user

    user == current_user || current_user.admin?
  end

  # Confirms that this user can edit; sets @user to the user to process
  def redir_unless_current_user_can_edit
    @user = User.find(params[:id])
    redirect_to(root_path) unless current_user_can_edit(@user)
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
