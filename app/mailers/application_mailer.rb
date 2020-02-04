# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is the root class for mailers.
# See the other files in this directory for mailers that do something.

class ApplicationMailer < ActionMailer::Base
  default from: "badgeapp@#{ENV['PUBLIC_HOSTNAME'].presence || 'localhost'}"
  layout 'mailer'

  # This X-SMTPAPI value disables SendGrid's clicktracking.
  # See: https://sendgrid.com/docs/API_Reference/SMTP_API/apps.html
  NORMAL_X_SMTPAPI =
    '{ "filters" : { "clicktrack" : { "settings" : { "enable" : 0 } } } }'

  # All mailer actions should call this unless they have a special need.
  # This allows us to have different values; we cannot override
  # Rails.application.config.action_mailer.default_options, and the docs are
  # wrong; once headers[]= is set, setting it to nil doesn't undo it.
  def set_standard_headers
    headers['X-SMTPAPI'] = NORMAL_X_SMTPAPI
  end
end
