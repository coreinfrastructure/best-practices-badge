# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# If environment variable BADGEAPP_DENY_LOGIN has a non-blank value
# ("true" is recommended), then no on can log in or do things logged-in
# users can do (such as edit anything).
Rails.application.config.deny_login = ENV['BADGEAPP_DENY_LOGIN'].present?
