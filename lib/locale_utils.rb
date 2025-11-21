# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'http_accept_language/parser'
require 'uri'

# Utility module for locale-related operations
# Provides shared methods for locale detection and URL manipulation
# Used by controllers and routing layer to avoid object instantiation overhead
module LocaleUtils
  # Find the best-matching locale for a given request,
  # when the user did not specify a locale in the URL.
  # Uses the following rules:
  # 1. Use the browser's ACCEPT_LANGUAGE best-matching locale
  #    in automatic_locales (if the browser gives us a matching one).
  # 2. Otherwise, fall back to the I18n.default_locale value.
  #
  # @param request [ActionDispatch::Request, Rack::Request] The HTTP request object
  # @return [Symbol] The best matching locale as a symbol
  def self.find_best_locale(request)
    # Get the HTTP_ACCEPT_LANGUAGE header from the request
    accept_language_header = request.env['HTTP_ACCEPT_LANGUAGE']

    # Create a parser to analyze the browser's language preferences
    parser = HttpAcceptLanguage::Parser.new(accept_language_header)

    # Find the best match from automatic locales
    browser_locale = parser.preferred_language_from(
      Rails.application.config.automatic_locales
    )

    return browser_locale.to_sym if browser_locale.present?

    I18n.default_locale
  end

  # Remove the "locale=value", if any, from the url_query provided
  # @param url_query [String, nil] The query string to process
  # @return [String, nil] The query string with locale parameter removed
  def self.remove_locale_query(url_query)
    (url_query || '').gsub(/\Alocale=[^&]*&?|&locale=[^&]*/, '').presence
  end

  # Reply with original_url modified so it has locale "locale".
  # Locale may be nil.
  # The rootmost path always has a trailing slash ("http://a.b.c/").
  # Otherwise, there is never a trailing slash.
  # To do this, we remove any locale in the query string and
  # and previously-specified locale.
  #
  # @param original_url [String] The URL to modify
  # @param locale [String, Symbol, nil] The locale to insert into the URL
  # @return [String] The modified URL with locale parameter
  # rubocop: disable Metrics/AbcSize
  def self.force_locale_url(original_url, locale)
    url = URI.parse(original_url)
    url.host = ENV.fetch('PUBLIC_HOSTNAME', url.host)
    # Remove locale from query string and main path.  The removing
    # substitution will sometimes remove too much, so we prepend a '/'
    # if that happens.
    url.query = remove_locale_query(url.query)
    new_path = url.path.gsub(%r{\A\/[a-z]{2}(-[A-Za-z0-9-]+)?(\/|\z)}, '')
    new_path.prepend('/') if new_path.empty? || new_path.first != '/'
    new_path.chomp!('/') if locale || new_path != '/'
    # Recreate path, but now forcibly include the locale.
    url.path = (locale.present? ? '/' + locale.to_s : '') + new_path
    url.to_s
  end
  # rubocop: enable Metrics/AbcSize
end
