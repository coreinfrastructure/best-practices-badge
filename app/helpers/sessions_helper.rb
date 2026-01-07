# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require_relative '../../lib/locale_utils'

# rubocop:disable Metrics/ModuleLength
module SessionsHelper
  SESSION_TTL = 48.hours # Automatically log off session if inactive this long
  RESET_SESSION_TIMER = 1.hour # Active sessions older than this reset timer
  GITHUB_PATTERN = %r{
    \Ahttps://github.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)/?\Z
  }x

  # Remove the "locale=value", if any, from the url_query provided
  # Delegates to LocaleUtils for implementation
  delegate :remove_locale_query, to: :LocaleUtils

  # Reply with original_url modified so it has locale "locale".
  # Locale may be nil.
  # The rootmost path always has a trailing slash ("http://a.b.c/").
  # Otherwise, there is never a trailing slash.
  # Delegates to LocaleUtils for implementation
  delegate :force_locale_url, to: :LocaleUtils

  # Low-level route to set user as being logged in.
  # This doesn't set the last_login_at or forward elsewhere.
  # rubocop:disable Metrics/AbcSize
  def log_in(user)
    session[:user_id] = user.id
    # Switch to user's preferred locale
    I18n.locale = user.preferred_locale.to_sym
    return unless session[:forwarding_url]

    session[:forwarding_url] = force_locale_url(
      session[:forwarding_url], I18n.locale
    )
  end
  # rubocop:enable Metrics/AbcSize

  # Returns the current User instance (db record) of the logged-in user,
  # or nil if the user is not logged in.
  # Lazy-loads from the database only when it's not already loaded.
  # To determine the id of the current user it uses
  # @session_user_id set by ApplicationController#setup_authentication_state.
  # Note that we check if the instance variable is *defined* - that way,
  # if we can't find a user, we don't keep searching for it on each request.
  #
  # @return [User, nil] Current user or nil
  def current_user
    return unless @session_user_id # Return nil if no user logged in
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: @session_user_id)
    @current_user
  end

  # Returns true if a user is logged in, false otherwise.
  # Just checks instance variable - no database query needed.
  #
  # @return [Boolean] true if logged in
  def logged_in?
    @session_user_id.present?
  end

  def require_logged_in
    throw(:abort) unless logged_in?
  end

  # Returns true if current user is an admin.
  # Checks instance var first to avoid DB query if not logged in.
  #
  # @return [Boolean] true if admin
  def current_user_is_admin?
    @session_user_id.present? && current_user&.admin?
  end

  # Remembers a user in a persistent session in a permanent cookie.
  # This is cryptographically secure, because we protect it in the permanent
  # cookies using Rails' mechanisms. This means that if an attacker
  # gains access to the remember token (e.g., by capturing the browser's
  # cookie values), the attacker will be gain persistent access to the
  # user's account. However, this is *not* considered a vulnerability, since
  # that is the *point* of the remember token, and this only occurs when
  # a user specifically requests it. We could try to add device fingerprinting,
  # but an attacker could forge that.
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # Forgets a persistent session
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Return true iff the current user can edit the given url.
  #
  # The GitHub API documentation here:
  # https://developer.github.com/v3/repos/collaborators/
  # #review-a-users-permission-level
  # says that if you retrieve:
  # GET /repos/:owner/:repo/collaborators/:username/permission
  # If "permission" is write or admin then that user can modify it.
  # HOWEVER, the use of that API is not allowed with an OAuth token, only
  # normal access token. So while that *looks* useful, it doesn't work for our
  # situation.
  #
  # As of 2020-04-16, retrieving a repo using GitHub repos API (using
  # https://api.github.com/:owner/:repo) with a users OAuth token will include
  # a field `permissions`.  We consider a user with `push` permissions an
  # editor and check for that.
  def github_user_can_push?(url, client = Octokit::Client)
    return false unless @session_user_token

    github_path = get_github_path(url)
    return false if github_path.nil?

    github = client.new access_token: @session_user_token
    begin
      github.repo(github_path).permissions.presence && github.repo(github_path).permissions[:push]
    # If you suddenly get a lot of 503's most likely github has changed
    # its API, make this a generic rescue
    # Disable rubocop - Style/RescueStandardError if that is needed
    rescue Octokit::NotFound
      return false
    end
  end

  def current_user_is_github_owner?(url)
    logged_in? && current_user.present? && current_user.provider == 'github' &&
      @session_github_name == get_github_owner(url)
  end

  # Retrieve list of public GitHub projects for a user, used when displaying
  # user profile. Returns up to 100 most recently updated public repositories
  # across all types (owned, org member, collaborator).
  # Only public repos are returned since badges are for public projects.
  # We don't retrieve *all* of them, because for some users that would
  # produce an overwhelming number.
  # Returns empty array on error to prevent 500 errors.
  def github_user_projects(client = Octokit::Client)
    return [] unless @session_user_token

    github = client.new access_token: @session_user_token
    github.repos(type: 'public', sort: 'updated', per_page: 100)
          .map(&:html_url).compact_blank
  rescue Octokit::Error => e
    Rails.logger.warn(
      "GitHub API error in github_user_projects: #{e.class} - #{e.message}"
    )
    []
  end

  # Logs out the current user.
  def log_out
    forget(current_user)
    reset_session
    @current_user = nil
  end

  # Returns true iff the current_user can *control* the @project.
  # This includes the right to delete the entry & to remove users who can edit.
  # Only the project badge entry owner and admins *control* the project entry.
  # Checks instance var first to avoid DB query if not logged in.
  #
  # @return [Boolean] true if can control
  def can_control?
    # If not logged in, clearly there's no control. Fast check, no DB query
    return false if @session_user_id.nil?
    # Fast check, no DB query on user
    return true if @session_user_id == @project.user_id
    # Check if user is admin - that DOES require a DB check
    return true if current_user.admin?

    false
  end

  # Returns true iff the current_user can *edit* the @project data.
  # This is a session helper because we use the session to ask GitHub
  # for the list of projects the user can edit.
  # Checks instance var first to avoid DB query if not logged in.
  #
  # @return [Boolean] true if can edit
  def can_edit?
    return false if @session_user_id.nil? # Fast check, no DB query
    return true if can_control?
    return true if AdditionalRight.exists?(
      project_id: @project.id, user_id: current_user.id
    )
    return true if can_current_user_edit_on_github?(@project.repo_url)

    false
  end

  # Returns true iff the current_user can push to the @project repo
  # according to GitHub.  We try to avoid calling GitHub if it is
  # is obviously unnecessary.
  def can_current_user_edit_on_github?(url)
    return false unless current_user.provider == 'github' &&
                        valid_github_url?(url)

    current_user_is_github_owner?(url) || github_user_can_push?(url)
  end

  # Returns true iff this is not the REAL final production system,
  # including the master/main and staging systems.
  # It only returns false if we are "truly in production"
  def in_development?(is_real = ENV.fetch('BADGEAPP_REAL_PRODUCTION', nil))
    return is_real.nil?
  end

  # Redirects to stored location (or to the default)
  def redirect_back_or(default)
    forwarding_url = session[:forwarding_url]
    session.delete(:forwarding_url)
    redirect_to(forwarding_url || force_locale_url(default, I18n.locale))
  end

  # Stores the URL trying to be accessed (if its a new project) or a referer
  def store_location_and_locale
    session.delete(:forwarding_url)
    session.delete(:locale)
    session[:locale] = I18n.locale
    return unless request.get?

    if request.url == new_project_url
      session[:forwarding_url] = new_project_url
    else
      store_internal_referer
    end
  end

  private

  def get_github_owner(url)
    return unless url.present? && valid_github_url?(url)

    url.match(GITHUB_PATTERN).captures.first
  end

  def get_github_path(url)
    return unless url.present? && valid_github_url?(url)

    url.match(GITHUB_PATTERN).captures.join('/')
  end

  # Check if referring url is internal, if so, save it.
  def store_internal_referer
    return if request.referer.nil?

    ref_url = request.referer
    return unless URI.parse(ref_url).host == request.host
    return if [login_url, signup_url].include? ref_url

    session[:forwarding_url] = ref_url
  end

  def valid_github_url?(url)
    url.present? && url.match(GITHUB_PATTERN).present?
  end
end
# rubocop:enable Metrics/ModuleLength
