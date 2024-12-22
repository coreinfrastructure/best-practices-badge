# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Load the Rails application.
require_relative 'application'

# Eliminate deprecation warning that
# > `to_time` will always preserve the receiver timezone rather than
# > system local time in Rails 8.1. To opt in to the new behavior,
# > set `config.active_support.to_time_preserves_timezone = :zone`
# In practice we only use UTC in operational systems anyway.

Rails.configuration.active_support.to_time_preserves_timezone = :zone

# Initialize the Rails application.
Rails.application.initialize!
