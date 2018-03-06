# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class StaticPagesController < ApplicationController
  include SessionsHelper

  def home
    preferred_url = force_locale_url(request.original_url, I18n.locale)
    redirect_to preferred_url unless request.original_url == preferred_url
  end

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
    redirect_to preferred_url
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end
end
