# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ipaddr'

class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Record the original session value in "original_session".
  # That way we tell if the session value has changed, and potentially
  # omit it if it has not changed.
  before_action :record_original_session
  def record_original_session
    @original_session = session.to_h
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # For the PaperTrail gem
  before_action :set_paper_trail_whodunnit

  # Limit time before must log in again.
  before_action :validate_session_timestamp
  after_action :persist_session_timestamp

  # If locale is not provided in the URL, redirect to best option.
  # Special URLs which do not have locales, such as "/robots.txt",
  # must "skip_before_action :redir_missing_locale".
  before_action :redir_missing_locale

  # Set the locale, based on best available information.
  before_action :set_locale_to_best_available

  # Force http -> https
  before_action :redirect_https

  # Validate client IP address (if only some IP addresses are allowed);
  # counters cloud piercing.
  before_action :validate_client_ip_address

  # Use the new HTTP security header, "permissions policy", to disable things
  # we don't need.
  before_action :add_http_permissions_policy

  # Record user_id, e.g., so it can be recorded in logs
  # https://github.com/roidrage/lograge/issues/23
  def append_info_to_payload(payload)
    super
    payload[:uid] = current_user.id if logged_in?
  end

  # How long (in seconds) will the badge be stored on the CDN before being
  # re-requested? This is used by set_cache_control_header.
  # A longer time reduces server load, but if we produce a wrong/obsolete
  # answer it will be wrong/obsolete for this long unless we explicitly purge.
  # 86400 = 1 day, 864000 = 10 days
  BADGE_CACHE_MAX_AGE = (ENV['BADGEAPP_BADGE_CACHE_MAX_AGE'] || '864000').to_i

  # How long (in seconds) will the badge be served by the CDN if it can't
  # get a response from us?
  # This provides a safety measure if the site goes down;
  # the CDN will keep serving *some* data for a while.
  # 864000 = 10 days, 1728000 = 20 days, 8640000 = 100 days
  # We force it to be at least twice the BADGE_CACHE_MAX_AGE.
  BADGE_CACHE_STALE_AGE = [
    (ENV['BADGEAPP_BADGE_CACHE_MAX_AGE'] || '8640000').to_i,
    2 * BADGE_CACHE_MAX_AGE
  ].max

  BADGE_CACHE_SURROGATE_CONTROL =
    "max-age=#{BADGE_CACHE_MAX_AGE}, stale-if-error=#{BADGE_CACHE_STALE_AGE}"

  # Set the cache control headers
  # More info:
  # https://docs.fastly.com/en/guides/configuring-caching
  # https://docs.fastly.com/en/guides/serving-stale-content
  # Simlulates what this did: https://github.com/fastly/fastly-rails
  # In particular:
  # https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/
  # action_controller/cache_control_headers.rb
  # rubocop:disable Naming/AccessorMethodName
  def set_cache_control_headers
    # Configure our CDN (Fastly) to cache data for a while, and
    # serve old data if the system has an error for some reason.
    # In deployment this heading is *only* used by the CDN, and is stripped
    # so that it does *not* go to client browsers.
    response.headers['Surrogate-Control'] = BADGE_CACHE_SURROGATE_CONTROL
    # Set the cache values for ordinary browsers (all *other* than the CDN).
    # The "no-cache" term is a little misleading, it *is* cached, but
    # the cache value must be verified (via the CDN) before its use.
    response.headers['Cache-Control'] = 'public, no-cache'
  end

  # Set headers for a CDN surrogate key. See:
  # https://github.com/fastly/fastly-rails
  # The keys are normally created via methods in the model.
  def set_surrogate_key_header(*surrogate_keys)
    # request.session_options[:skip] = true  # No Set-Cookie
    response.headers['Surrogate-Key'] = surrogate_keys.join(' ')
  end
  # rubocop:enable Naming/AccessorMethodName

  # Omit useless unchanged session cookie by not-logged-in users
  # to improve performance & privacy.
  # For example, setting a cookie disables some caches.
  # *DO NOT* set error messages in the flash area after calling this method,
  # because flashes are stored in the session.
  # This is vaguely inspired by, but takes a different approach, to
  # https://stackoverflow.com/questions/5435494/
  # rails-3-disabling-session-cookies
  # You can verify this directly by running commands such as:
  # curl -svo ,out --max-redirs 10 http://localhost:3000/en
  # and verifying the absence of the header Set-Cookie header,
  # which would otherwise look like this:
  # Set-Cookie: _BadgeApp_session=..data--data..; path=/; HttpOnly
  # We have to send the cookie for logged-in users, or the CSRF counter
  # token might not be sent (it's set very late in the pipeline),
  # with the result that logged-in users couldn't log out (via /logout).
  # Don't call this routine from a session management function or a
  # page that leads to database changes (an edit page); those set the CSRF
  # counter token, so calling this routine will cause those actions to fail.
  def omit_unchanged_session_cookie
    # Only take this action if not-logged-in and session cookie is unchanged
    return unless !logged_in? && session.to_h == @original_session

    request.session_options[:skip] = true
  end

  private

  # *Always* include the locale when generating a URL.
  # Historically we omitted the locale when it was "en", but then we could
  # not tell the difference between "use en" and "use the browser's locale".
  # So, we now *always* include the locale in the URL once we know what it is;
  # if there's no locale in the URL, that means we must use heuristics
  # to figure out what it should be and redirect to that locale.
  # To omit the locale for "en",
  # see this: http://stackoverflow.com/questions/5261521/
  # how-to-avoid-adding-the-default-locale-in-generated-urls
  # { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  # rubocop: disable Style/OptionHash
  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end
  # rubocop: enable Style/OptionHash

  # raise exception if text value client_ip isn't in valid_client_ips
  def fail_if_invalid_client_ip(client_ip, allowed_ips)
    return if client_ip.blank?

    client_ip_data = IPAddr.new(client_ip)
    return unless client_ip_data
    return if allowed_ips.any? do |range|
      range.include?(client_ip_data)
    end

    raise ActionController::RoutingError.new('Invalid client IP'),
          'Invalid client IP'
  end

  # See: http://stackoverflow.com/questions/4329176/
  #   rails-how-to-redirect-from-http-example-com-to-https-www-example-com
  def redirect_https
    if Rails.application.config.force_ssl && !request.ssl?
      redirect_to protocol: 'https://', status: :moved_permanently
    end
    true
  end

  # Find the best-matching locale,
  # because the user did not specify a locale in the URL.
  # We use the following rules:
  # 1. Use the browser's ACCEPT_LANGUAGE best-matching locale
  # in automatic_locales (if the browser gives us a matching one).
  # 2. Otherwise, fall back to the I18n.default_locale value.
  # Note that the user can *ALWAYS* express the preferred locale in the URL.
  # We do *NOT* use cookies (these aren't RESTful and thus cause problems),
  # and users can always override with a URL even if their browser's locale
  # is not configured correctly.
  # We could use geolocation in the future, but we would only do so if
  # the user hasn't specified a locale in the URL *and* the browser hasn't
  # requested a locale.  Geolocation is problematic: some user's locales
  # will not be the common one in the geolocation, and we must avoid
  # online services (that would leak user IP addresses to those services).
  # Browsers often provide ACCEPT_LANGUAGE (which in turn is often provided
  # by the operating system), so we should not need geolocation anyway.
  def find_best_locale
    browser_locale =
      http_accept_language.preferred_language_from(
        Rails.application.config.automatic_locales
      )
    return browser_locale if browser_locale.present?

    I18n.default_locale
  end

  # Special case: If the requested format is JSON or CSV, don't bother
  # redirecting, because JSON and CSV are normally the same in any locale.
  DO_NOT_REDIRECT_LOCALE = %w[json csv].freeze

  # If locale is not provided in the URL, redirect to best option.
  # NOTE: This is intentionally skipped by some calls, e.g., session create.
  # See <http://guides.rubyonrails.org/i18n.html>.
  def redir_missing_locale
    explicit_locale = params[:locale]
    return if explicit_locale.present?

    # Don't bother redirecting some formats
    return if DO_NOT_REDIRECT_LOCALE.include?(params[:format])

    #
    # No locale, determine the best locale and redirect.
    #
    best_locale = find_best_locale
    preferred_url = force_locale_url(request.original_url, best_locale)
    # It's not clear what status code to provide on a locale-based redirect.
    # However, we must avoid 301 (Moved Permanently), because it is certainly
    # not a permanent move.
    # We previously used use 300 (Multiple Choices),
    # because that code indicates there's a redirect based on agent choices
    # (which is certainly true), by doing this:
    # redirect_to preferred_url, status: :multiple_choices # 300
    # It worked on staging, but causes problems in production when trying
    # to redirect the root path, so as emergency we're
    # switching to "found" (302) which is supported by everyone.
    redirect_to preferred_url, status: :found
  end

  # Set the locale, based on best available information.
  # See <http://guides.rubyonrails.org/i18n.html>.
  def set_locale_to_best_available
    best_locale = params[:locale] # Locale in URL always takes precedent
    best_locale = find_best_locale if best_locale.blank?

    # Assigning a value to I18n.locale *looks* like a
    # global variable setting, and setting a global
    # variable would be bad since we're multi-threaded.
    # However, this is *not* setting a global variable, it's setting a
    # per-Thread value (which is safe). Per the i18n guide,
    # "The locale can be either set pseudo-globally to I18n.locale
    # (which uses Thread.current like, e.g., Time.zone)...".
    I18n.locale = best_locale.to_sym
  end

  # Validate client IP address if Rails.configuration.valid_client_ips
  # and header value X-Forwarded-For.
  # This can provide a defense against cloud piercing.
  def validate_client_ip_address
    return unless Rails.configuration.valid_client_ips

    client_ip = request.remote_ip
    fail_if_invalid_client_ip(client_ip, Rails.configuration.valid_client_ips)
  end

  # Use the new HTTP security header, "Permissions policy", to disable things
  # we don't need. It was formerly named "feature policy" with a slightly
  # different syntax. See:
  # https://scotthelme.co.uk/goodbye-feature-policy-and-hello-permissions-policy
  # https://httptoolkit.tech/blog/renaming-feature-policy-to-permissions-policy
  # https://scotthelme.co.uk/a-new-security-header-feature-policy/
  # Note that this *gives up* fullscreen & sync-xhr; if we need it later,
  # change the policy.
  # rubocop: disable Metrics/MethodLength
  def add_http_permissions_policy
    response.set_header(
      'Permissions-Policy',
      'fullscreen=(), geolocation=(), midi=(), ' \
      'notifications=(), push=(), sync-xhr=(), microphone=(), ' \
      'camera=(), magnetometer=(), gyroscope=(), speaker=(), ' \
      'vibrate=(), payment=()'
    )
    # Include the older Feature-Policy header, for older browser versions.
    # We can eventually drop this, but it doesn't hurt to include it for now.
    response.set_header(
      'Feature-Policy',
      "fullscreen 'none'; geolocation 'none'; midi 'none';" \
      "notifications 'none'; push 'none'; sync-xhr 'none'; microphone 'none';" \
      "camera 'none'; magnetometer 'none'; gyroscope 'none'; speaker 'none';" \
      "vibrate 'none'; payment 'none'"
    )
  end
  # rubocop: enable Metrics/MethodLength

  include SessionsHelper
end
