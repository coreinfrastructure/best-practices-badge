# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'ipaddr'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # For the PaperTrail gem
  before_action :set_paper_trail_whodunnit

  # Limit time before must log in again.
  before_action :validate_session_timestamp
  after_action :persist_session_timestamp

  # Set user's locale; see <http://guides.rubyonrails.org/i18n.html>.
  before_action :set_locale

  # Force http -> https
  before_action :redirect_https

  # Validate client IP address (if only some IP addresses are allowed);
  # counters cloud piercing.
  before_action :validate_client_ip_address

  # Record user_id, e.g., so it can be recorded in logs
  # https://github.com/roidrage/lograge/issues/23
  def append_info_to_payload(payload)
    super
    payload[:uid] = current_user.id if logged_in?
  end

  # NOTE: In tests use "controller.root_url(...)", not "root_url",
  # and similarly for root_path, because we override those methods
  # here in the application controller.

  # Return root path in form "/" + locale.  Rails prefers
  # "/?locale=LOCALE_NAME" which is general but ugly.
  # We can have cleaner and simpler URLs by simply never using
  # a top-level component with the same syntax as a locale name.
  def root_path(**args)
    '/' + locale_path_component(args)
  end

  # Return root url in form "/" + locale.
  # Where practical, use root_path instead of root_url.
  # See comments on root_path for more information.
  # This does NOT fully support the normal Rails args for root_url.
  def root_url(**args)
    super(locale: nil) + locale_path_component(args)
  end

  private

  # Return locale path component (as a string).  If the locale is in args,
  # use that, otherwise use the current locale.
  def locale_path_component(args)
    locale = args[:locale]
    locale = I18n.locale if locale.blank?
    locale ? locale.to_s : ''
  end

  # *Always* include the locale when generating a URL.
  # Historically we omitted the locale when it was "en", but then we could
  # not tell the difference between "use en" and "use the browser's locale".
  # So, we now *always* generate the locale.  To omit the locale for "en",
  # see this: http://stackoverflow.com/questions/5261521/
  # how-to-avoid-adding-the-default-locale-in-generated-urls
  # { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end

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

  # Find the best-matching locale, under the following rules:
  # 1. Always choose the locale if explicitly given.
  # 2. Otherwise, use the browser's ACCEPT_LANGUAGE best-matching locale
  # in automatic_locales (if the browser gives us a matching one).
  # 3. Otherwise, fall back to the I18n.default_locale.
  # Note that the user can *ALWAYS* express the preferred locale in the URL.
  # We do *NOT* use geolocation (users may prefer something different),
  # we do *NOT* use cookies (these aren't RESTful and thus cause problems),
  # and users can always override with a URL even if their browser's locale
  # is not configured correctly.
  def find_best_locale
    explicit_locale = params[:locale]
    return explicit_locale if explicit_locale
    browser_locale =
      http_accept_language.preferred_language_from(
        Rails.application.config.automatic_locales
      )
    return browser_locale if browser_locale.present?
    I18n.default_locale
  end

  # This *looks* like a global variable setting, and setting a global
  # variable would be bad since we're multi-threaded.
  # However, this is *not* setting a global variable, it's setting a
  # per-Thread value (which is safe). Per the i18n guide,
  # "The locale can be either set pseudo-globally to I18n.locale
  # (which uses Thread.current like, e.g., Time.zone)...".
  def set_locale
    best_locale = find_best_locale
    I18n.locale = find_best_locale if best_locale.present?
  end

  # Validate client IP address if Rails.configuration.valid_client_ips
  # and header value X-Forwarded-For.
  # This can provide a defense against cloud piercing.
  def validate_client_ip_address
    return unless Rails.configuration.valid_client_ips
    client_ip = request.remote_ip
    fail_if_invalid_client_ip(client_ip, Rails.configuration.valid_client_ips)
  end

  include SessionsHelper
end
