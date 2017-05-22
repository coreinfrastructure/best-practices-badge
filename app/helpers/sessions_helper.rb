# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module SessionsHelper
  SESSION_TTL = 48.hours # Automatically log off session if inactive this long

  require 'uri'

  # Add/change locale information in URL query if needed.  Modifies url.
  def force_locale_url_query(url, locale)
    return unless url.path == '' ||
                  url.path == '/' || url.query =~ /\Alocale=.*\Z/
    url.query = locale == :en ? nil : 'locale=' + locale.to_s
  end

  # Change locale of original_url.
  # Presumes that query is empty or only has a locale.
  # rubocop:disable Metrics/AbcSize
  def force_locale_url(original_url, locale)
    url = URI.parse(original_url)
    # Clean up path
    url.path.gsub!(%r{\A\/[a-z]{2}(-[A-Za-z0-9-]*)?\/}, '') # Remove old locale
    url.path = '/' + url.path if url.path == '' || url.path[0] != '/'
    if locale != :en && url.path.length > 1
      url.path = '/' + locale.to_s + url.path
    end
    force_locale_url_query url, locale
    url.to_s
  end
  # rubocop:enable Metrics/AbcSize

  def log_in(user)
    session[:user_id] = user.id
    # Switch to user's preferred locale, but only if the current locale is :en
    # (any other locale is an intentional selection & thus should be retained)
    I18n.locale = user.preferred_locale.to_sym if I18n.locale == :en
    return unless session[:forwarding_url]
    session[:forwarding_url] = force_locale_url(
      session[:forwarding_url], I18n.locale
    )
  end

  # Returns the user corresponding to the remember token cookie
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
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

  def github_user_projects
    github = Github.new oauth_token: session[:user_token], auto_pagination: true
    github.repos.list.map(&:html_url).reject(&:blank?)
  end

  # Logs out the current user.
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def can_make_changes?
    project_id = params[:id]
    if current_user.nil?
      false
    elsif current_user.projects.exists?(id: project_id)
      true
    elsif current_user.admin?
      true
    elsif current_user.provider == 'github'
      project = Project.find_by(id: project_id)
      return false unless project.repo_url?
      github_user_projects.include? project.repo_url
    else
      false
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Redirects to stored location (or to the default)
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed (if its a new project) or a referer
  def store_location
    session.delete(:forwarding_url)
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
    session[:forwarding_url] = ref_url unless ref_url == login_url
  end
end
# rubocop:enable Metrics/ModuleLength
