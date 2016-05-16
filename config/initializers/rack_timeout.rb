# frozen_string_literal: true
# Set response timeout; used by gem 'rack-timeout'
# See: https://github.com/heroku/rack-timeout

Rack::Timeout.timeout = 28 # seconds
