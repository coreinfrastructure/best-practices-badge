# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ipaddr'

# Base controller for the Best Practices Badge application.
# Provides common functionality including session management, security headers,
# locale handling, HTTPS enforcement, and CDN cache configuration.
# All other controllers inherit from this class.
#
# rubocop: disable Metrics/ClassLength
class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Record the original session value in "original_session".
  # That way can we tell if the session value has changed, and potentially
  # omit it if it has not changed.
  before_action :record_original_session

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # For the PaperTrail gem
  before_action :set_paper_trail_whodunnit

  # Limit time before must log in again.
  # The `validate_session_timestamp` will log out users once their
  # login session time has expired, and it's checked before any main
  # action unless specifically exempted.
  before_action :validate_session_timestamp
  after_action :persist_session_timestamp

  # If locale is not provided in the URL, redirect to best option.
  # Special URLs which do not have locales, such as "/robots.txt",
  # must "skip_before_action :redir_missing_locale".
  before_action :redir_missing_locale

  # Set the locale, based on best available information.
  # The locale in the URL always takes precedent.
  before_action :set_locale_to_best_available

  # Force http -> https
  before_action :redirect_https?

  # Validate client IP address (if only some IP addresses are allowed);
  # counters cloud piercing.
  before_action :validate_client_ip_address

  # Use the new HTTP security header, "permissions policy", to disable things
  # we don't need.
  before_action :add_http_permissions_policy

  # Set the default cache control, which inhibits external caching.
  # If you *want* caching, you must apply:
  # skip_before_action :set_default_cache_control
  # We use before_action and override CSRF cache control
  before_action :set_default_cache_control

  # Records the current session state for comparison later.
  # Used to detect session changes and optimize session cookie transmission.
  # @return [void]
  def record_original_session
    @original_session = session.to_h
  end

  # Append user information to the log payload for request tracking.
  # Records the current user's ID in logs when user is logged in.
  #
  # @param payload [Hash] The log payload hash to append information to
  # @return [void]
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

  # Delay in seconds before a delayed purge
  BADGE_PURGE_DELAY = (ENV['BADGEAPP_PURGE_DELAY'] || '8').to_i

  # Combined cache control header value for CDN surrogate control
  BADGE_CACHE_SURROGATE_CONTROL =
    "max-age=#{BADGE_CACHE_MAX_AGE}, stale-if-error=#{BADGE_CACHE_STALE_AGE}"

  # Set default cache control - don't externally cache.
  # This is the safe behavior, so we make it the default.
  # Fewer pages are cacheable than you might initially expect.
  # Most of the pages on this site vary depending on whether or not
  # you're logged in (because the header varies), so we can't cache most
  # of the pages. Many pages can also display a "flash" error message
  # and/or have CSRF protections that are per-user.
  # If we ever change the system so that the pages are mostly
  # the *same* regardless of the logged-in situation and whether or not
  # flashes were present, we could be more aggressive about caching.
  # This does NOT impact static images which are handled separately.
  def set_default_cache_control
    # Override Rails default behavior by setting stricter cache control
    # This will be our baseline, and if CSRF protection overrides it,
    # we'll handle that in the after_action
    response.headers['Cache-Control'] = 'private, no-cache'
  end

  # Externally *CACHE* this result: ask the CDN to cache it, and for browsers
  # to optionally cache it but validate its contents before display.
  # Calls which use this must ALSO apply:
  # skip_before_action :set_default_cache_control
  # and should set:
  # set_surrogate_key_header VALUE
  # More info:
  # - https://docs.fastly.com/en/guides/configuring-caching
  # - https://docs.fastly.com/en/guides/serving-stale-content
  # Simulates what this did: https://github.com/fastly/fastly-rails
  # In particular:
  # https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/
  # @return [void]
  # rubocop:disable Naming/AccessorMethodName
  def cache_on_cdn
    # Configure our CDN (Fastly) to cache data for a while, and
    # serve old data if the system has an error for some reason.
    # In deployment this heading is *only* used by the CDN, and is stripped
    # so that it does *not* go to client browsers.
    response.headers['Surrogate-Control'] = BADGE_CACHE_SURROGATE_CONTROL

    # Set the cache values control values.
    # The value 'no-cache' is a standard but misleading name, it permits
    # the web browser to have a *local* cache but it requires the web
    # browser to revalidate the data before each use, and this direction
    # is ignored by the CDN (Fastly).
    # 'public' simply means "anyone can store a copy".
    # Thus, this result *is* cached! This setting means that:
    # - the CDN *DOES* cache it, and doesn't keep verifying its value with
    #   the backing server. Instead, this data will be served directly
    #   from the CDN until it times out or is expressly purged.
    # - the web browser can cache it, but it must verify with the CDN
    #   if the value is current each time before displaying it.
    response.headers['Cache-Control'] = 'public, no-cache'
    omit_session_cookie
  end

  # Sets CDN surrogate key headers for cache management.
  # The keys are normally created via methods in the model.
  # Enables targeted purging of cached content by surrogate keys.
  # See: https://github.com/fastly/fastly-rails
  #
  # @param surrogate_keys [Array<String>] Keys for cache identification
  # @return [void]
  def set_surrogate_key_header(*surrogate_keys)
    # request.session_options[:skip] = true  # No Set-Cookie
    response.headers['Surrogate-Key'] = surrogate_keys.join(' ')
  end
  # rubocop:enable Naming/AccessorMethodName

  # Completely disables caching for sensitive pages.
  # Uses **no-store** to prevent any caching of the response.
  # @return [void]
  def disable_cache
    # Misleadingly, "no-cache" *allows* caching. We must use 'no-store'
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    response.headers['Cache-Control'] = 'private, no-store'
    # We could remove header 'Surrogate-Control' but I found no need to do so.
  end

  # Omit session cookie.
  # This can improve performance and privacy for anonymous users by not sending
  # unnecessary session cookies when the session hasn't changed.
  #
  # **Important:** This has limited functionality.
  # - Don't display the longer header, as that depends on whether or not
  #   users are logged in, and we need the system to not cache that.
  #   Having a cookie makes it obvious to the CDN "don't cache this".
  #   In the longer term we may modify the system so that the header
  #   is constant and user-side JavaScript can omit items that can't be used,
  #   which would make the pages's CDN cache behavior MUCH better.
  # - Do not set flash messages after calling this method,
  #   as flashes are stored in the session.
  # - Don't set Rails CSRF tokens either, as they are also in the session.
  # Inspired by https://stackoverflow.com/questions/5435494/rails-3-disabling-session-cookies
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
  # counter token, so calling this routine will cause those actions to fail
  # @return [void]
  def omit_session_cookie
    request.session_options[:skip] = true
  end

  # Omit unchanged session cookie.
  # This has limited utility, see the comments on omit_session_cookie.
  # Only take this action if not-logged-in and session cookie is unchanged
  # def omit_unchanged_session_cookie
  #   return unless !logged_in? && session.to_h == @original_session
  #   omit_session_cookie
  # end

  # Response formats that should not trigger locale redirects.
  # JSON and CSV are locale-independent, so don't redirect to add locale.
  DO_NOT_REDIRECT_LOCALE = %w[json csv].freeze

  private

  # Ensures all URLs include the current locale parameter.
  # Always includes locale in URLs for consistent internationalization,
  # even when the locale matches the default.
  # If there's no locale in the URL, that means we must use heuristics
  # to figure out what it should be and redirect to that locale.
  # Once we know the locale, we want to stick to it consistently.
  # To omit the locale for "en",
  # see this: http://stackoverflow.com/questions/5261521/
  # how-to-avoid-adding-the-default-locale-in-generated-urls
  # { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  #
  # @param options [Hash] Additional URL options to merge
  # @return [Hash] URL options with locale included
  # rubocop: disable Style/OptionHash
  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end
  # rubocop: enable Style/OptionHash

  # Fail if the client IP is invalid.
  # raise exception if text value client_ip isn't in valid_client_ips
  # @param client_ip [String] The client IP address to validate
  # @param allowed_ips [Array] Array of allowed IP addresses
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

  # Redirect http: to https: in normal production use.
  # See: http://stackoverflow.com/questions/4329176/
  #   rails-how-to-redirect-from-http-example-com-to-https-www-example-com
  def redirect_https?
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
  # online services that would leak user IP addresses to those services.
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

    # Where we go varies by browser, so we can't cache this redirect
    disable_cache

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
# rubocop: enable Metrics/ClassLength
