# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Allow client-side JavaScript of other systems to make GET requests,
# but *only* get requests, from us.  We do *not* share credentials.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    # "credentials" is false (not sent) by default.
    resource '*', headers: :any, methods: [:get]
  end
end
