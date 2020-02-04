# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Disable SendGrid's clicktracking.
# See: https://sendgrid.com/docs/API_Reference/SMTP_API/apps.html
Rails.application.config.action_mailer.default_options = {
  'X-SMTPAPI' =>
    '{ "filters" : { "clicktrack" : { "settings" : { "enable" : 0 } } } }'
}
