# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class StaticPagesController < ApplicationController
  include SessionsHelper

  # If a page is *invariant* regardless of locale, don't bother
  # to figure out what the locale is.
  skip_before_action :set_locale_to_best_available, only: %i[robots]

  # There's no value in redirecting these pages to a locale,
  # so do *not* redirect them to a URL based on locale.
  skip_before_action :redir_missing_locale,
                     only: %i[robots error_404 google_verifier]

  # Omit useless unchanged session cookie for performance & privacy
  # We *must not* set error messages in the flash area,
  # because flashes are stored in the session.
  # Static pages operations never set the flash, so we can do this
  # in all cases as part of the before_action.
  before_action :omit_unchanged_session_cookie

  def home; end

  def criteria_stats; end

  def criteria_discussion; end

  # Send a 404 ("not found") page.  Inspired by:
  # http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  # This is intentionally short and does *NOT* use the standard layout,
  # to minimize CPU and bandwidth use during an attack.
  # Note that due to skip_before_action we don't redirect the URL,
  # as there's no need to do so and skipping a redirect will save a roundtrip.
  # We *do* try to guess the locale, since we can then provide a
  # locale-specific error message.
  def error_404
    # The default router already logs things, so we don't need to do more.
    # You can do something like this to log more information, but be sure
    # to escape attacker data to counter log forging:
    # logger.info 'Page not found'
    render(
      template: 'static_pages/error_404',
      formats: [:html], layout: false,
      status: :not_found
    )
  end

  # Weird special case: For David A. Wheeler to get log issues from Google,
  # we have to have a special file to let Google verify access.
  def google_verifier
    render(
      template: 'static_pages/google_verifier',
      layout: false,
      status: :ok
    )
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end
end
