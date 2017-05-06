# frozen_string_literal: true

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

  private

  def default_url_options
    # Include "/:locale" in URL unless it's en (we omit en to keep URLs stable)
    # http://stackoverflow.com/questions/5261521/
    # how-to-avoid-adding-the-default-locale-in-generated-urls
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
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

  # This *looks* like a global variable setting, and setting a global
  # variable would be bad since we're multi-threaded.
  # However, this is *not* setting a global variable, it's setting a
  # per-Thread value (which is safe). Per the i18n guide,
  # "The locale can be either set pseudo-globally to I18n.locale
  # (which uses Thread.current like, e.g., Time.zone)...".
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
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
