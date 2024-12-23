# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is the root class for mailers.
# See the other files in this directory for mailers that do something.

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('BADGEAPP_FROM', "badgeapp@#{ENV.fetch('PUBLIC_HOSTNAME', 'localhost')}")
  layout 'mailer'

  # Maximize privacy in the emails we send.
  # This X-SMTPAPI value disables SendGrid's clicktracking, opentracking, etc.
  # We expressly force these off to make *sure* they are off.
  # Clicktracking creates enables external track on click and makes ugly URLs.
  # Opentracking tracks email opens via an img reference.
  # Both clicktracking and opentracking are enabled by default (!).
  # See: https://sendgrid.com/docs/API_Reference/SMTP_API/apps.html and
  # https://sendgrid.com/docs/for-developers/sending-email/smtp-filters/
  # In almost all cases we send this as a constant string, so
  # we'll store it that way.
  NORMAL_X_SMTPAPI =
    '{ "filters" : { ' \
    '"clicktrack" : { "settings" : { "enable" : 0 } }, ' \
    '"ganalytics" : { "settings" : { "enable" : 0 } }, ' \
    '"subscriptiontrack" : { "settings" : { "enable" : 0 } }, ' \
    '"opentrack" : { "settings" : { "enable" : 0 } } ' \
    '} }'

  # This forces fast failure on start if NORMAL_X_SMTPAPI is not valid JSON
  NORMAL_X_SMTPAPI_JSON = JSON.parse(NORMAL_X_SMTPAPI).freeze

  # All mailer actions should call this unless they have a special need.
  # This allows us to have different values; we cannot override
  # Rails.application.config.action_mailer.default_options, and the docs are
  # wrong; once headers[]= is set, setting it to nil doesn't undo it.
  def set_standard_headers
    headers['X-SMTPAPI'] = NORMAL_X_SMTPAPI
  end
end
