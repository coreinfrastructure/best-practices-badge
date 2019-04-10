# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ModuleLength
module SessionsHelper
  SESSION_TTL = 48.hours # Automatically log off session if inactive this long
  PRODUCTION_HOSTNAME = 'bestpractices.coreinfrastructure.org'
  require 'uri'

  # Remove the "locale=value", if any, from the url_query provided
  def remove_locale_query(url_query)
    (url_query || '').gsub(/\Alocale=[^&]*&?|&locale=[^&]*/, '').presence
  end

  # Reply with original_url modified so it has locale "locale".
  # Locale may be nil.
  # The rootmost path always has a trailing slash ("http://a.b.c/").
  # Otherwise, there is never a trailing slash.
  # To do this, we remove any locale in the query string and
  # and previously-specified locale.
  # rubocop: disable Metrics/AbcSize
  def force_locale_url(original_url, locale)
    url = URI.parse(original_url)
    # Remove locale from query string and main path.  The removing
    # substitution will sometimes remove too much, so we prepend a '/'
    # if that happens.
    url.query = remove_locale_query(url.query)
    new_path = url.path.gsub(%r{\A\/[a-z]{2}(-[A-Za-z0-9-]+)?(\/|\z)}, '')
    new_path.prepend('/') if new_path.empty? || new_path[0] != '/'
    new_path.chomp!('/') if locale || new_path != '/'
    # Recreate path, but now forcibly include the locale.
    url.path = (locale.present? ? '/' + locale.to_s : '') + new_path
    url.to_s
  end
  # rubocop: enable Metrics/AbcSize

  # Low-level route to set user as being logged in.
  # This doesn't set the last_login_at or forward elsewhere.
  def log_in(user)
    session[:user_id] = user.id
    # Switch to user's preferred locale
    I18n.locale = user.preferred_locale.to_sym
    return unless session[:forwarding_url]

    session[:forwarding_url] = force_locale_url(
      session[:forwarding_url], I18n.locale
    )
  end

  # Returns the user corresponding to the remember token cookie
  # rubocop:disable Metrics/MethodLength
  def current_user
    return if Rails.application.config.deny_login
    # Extra parens used here to indicate safe assignment in condition
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(:remember, cookies[:remember_token])
        # Automatically re-log back in, and set timestamp
        log_in user
        persist_session_timestamp
        @current_user = user
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  def require_logged_in
    throw(:abort) unless logged_in?
  end

  def current_user_is_admin?
    logged_in? && current_user.admin?
  end

  # Remembers a user in a persistent session.
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

  # Return true iff an html_url in array repo_list is url.
  def repo_url_in?(repo_list, url)
    repo_list.any? { |project| project.html_url == url }
  end

  # Return true iff the current user can edit the given url.
  #
  # The GitHub API documentation here:
  # https://developer.github.com/v3/repos/collaborators/
  # #review-a-users-permission-level
  # says that if you retrieve:
  # GET /repos/:owner/:repo/collaborators/:username/permission
  # If "permission" is write or admin then that user can modify it.
  # HOWEVER, to use that API you have to have a token that's the admin
  # of the repo, otherwise you just get a "Bad credentials" message.
  # So while that *looks* useful, it doesn't work for our situation.
  #
  # The only way we've found that works for us is to ask GitHub to list the
  # repos this user can control, and then return true if there's a match.
  def github_user_projects_include?(url)
    github = Octokit::Client.new access_token: session[:user_token]
    github.auto_paginate = false
    page = 1
    repo_list = github.repos # Read first page of list
    loop do
      return false if repo_list.blank?
      return true if repo_url_in?(repo_list, url)
      # We should be able to do this, but it doesn't work:
      # return false if github.last_response.rels[:next].blank?
      # repo_list = github.last_response.rels[:next].get.data
      # So we'll retrieve by requesting page numbers instead.
      page += 1
      repo_list = github.repos(nil, page: page)
    end
  end

  # Retrieve list of all GitHub projects, used when displaying
  # user profile.
  def github_user_projects
    github = Octokit::Client.new access_token: session[:user_token]
    github.auto_paginate = true
    github.repos.map(&:html_url).reject(&:blank?)
  end

  # Logs out the current user.
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # Returns true iff the current_user can *control* the @project.
  # This includes the right to delete the entry & to remove users who can edit.
  # Only the project badge entry owner and admins *control* the project entry.
  def can_control?
    return false if current_user.nil?
    return true if current_user.admin?
    return true if current_user.id == @project.user_id

    false
  end

  # Returns true iff the current_user can *edit* the @project data.
  # This is a session helper because we use the session to ask GitHub
  # for the list of projects the user can edit.
  def can_edit?
    return false if current_user.nil?
    return true if can_control?
    return true if AdditionalRight.exists?(
      project_id: @project.id, user_id: current_user.id
    )
    return true if can_current_user_edit_on_github?(@project.repo_url)

    false
  end

  # Returns true iff the current_user can *edit* the @project repo
  # according to GitHub.  We try to avoid calling GitHub if it is
  # is obviously unnecessary.
  def can_current_user_edit_on_github?(url)
    current_user.provider == 'github' &&
      url.present? &&
      url.starts_with?('https://github.com/') &&
      github_user_projects_include?(url)
  end

  def in_development?
    hostname = ENV['PUBLIC_HOSTNAME']
    return true if hostname.nil?

    hostname != PRODUCTION_HOSTNAME
  end

  # Redirects to stored location (or to the default)
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] ||
                force_locale_url(default, I18n.locale))
    session.delete(:forwarding_url)
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

  def session_expired
    return true unless session.key?(:time_last_used)

    session[:time_last_used] < SESSION_TTL.ago.utc
  end

  def validate_session_timestamp
    return unless logged_in? && session_expired

    reset_session
    session[:current_user] = nil
    redirect_to login_path
  end

  def persist_session_timestamp
    session[:time_last_used] = Time.now.utc if logged_in?
  end

  private

  # Check if refering url is internal, if so, save it.
  def store_internal_referer
    return if request.referer.nil?

    ref_url = request.referer
    return unless URI.parse(ref_url).host == request.host
    return if [login_url, signup_url].include? ref_url

    session[:forwarding_url] = ref_url
  end
end
# rubocop:enable Metrics/ModuleLength
