# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is the root class for mailers.
# See the other files in this directory for mailers that do something.

class ApplicationMailer < ActionMailer::Base
  default from: "badgeapp@#{ENV['PUBLIC_HOSTNAME'].presence || 'localhost'}"
  layout 'mailer'
end
