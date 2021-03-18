# frozen_string_literal: true

# Copyright the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class BadgeStaticController < ApplicationController
  # Show a *static* badge view, independent of any project's status

  # The 'show' action is special and does NOT take a locale.
  skip_before_action :redir_missing_locale, only: :show

  # Cache this using the CDN
  before_action :set_cache_control_headers, only: %i[show]

  # rubocop:disable Metrics/MethodLength
  def show
    # Show the badge static display given a value.
    # "Value" must be 0..99, passing, silver, or gold
    # TODO: have a way to show "no such value"
    value = params[:value]
    begin
      value = Integer(value, 10) # Switch to integer type if it is
    rescue ArgumentError # not an integer - don't change "value"
    end

    # Defensive programming: check if it's valid before displaying it.
    # The router should prevent invalid values from reaching here.
    return unless Badge.valid?(value)

    set_surrogate_key_header "/badge_percent/#{value}"
    send_data Badge[value],
              type: 'image/svg+xml', disposition: 'inline'
    # Our application router now prevents invalid values. Before we did that,
    # we had an "else" clause that sent a 404 by doing this:
    # render(
    #   template: 'static_pages/error_404',
    #   formats: [:html], layout: false, status: :not_found # 404
    # )
  end
  # rubocop:enable Metrics/MethodLength
end
