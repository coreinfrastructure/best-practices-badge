# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class StaticPagesController < ApplicationController
  include SessionsHelper

  def home; end

  def criteria; end

  # Send a 404 ("not found") page.  Inspired by:
  # http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  def error_404
    # The default router already logs things, so we don't need to do more.
    # You can do something like this to log more information, but be sure
    # to escape attacker data to counter log forging:
    # logger.info 'Page not found'
    render(
      template: 'static_pages/error_404',
      layout: false,
      status: 404
    )
  end

  # Given a URL without a locale, redirect to the correct locale URL
  def redir_locale
    preferred_url = force_locale_url(request.original_url, I18n.locale)
    # It's not clear what status code to provide on a locale-based redirect.
    # However, we must avoid 301 (Moved Permanently), because it is certainly
    # not a permanent move.  For the moment we'll use 300 (Multiple Choices),
    # because that code indicates there's a redirect based on agent choices
    # (which is certainly true).
    redirect_to preferred_url, status: :multiple_choices # 300
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end
end
