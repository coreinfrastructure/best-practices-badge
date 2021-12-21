# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.test?
    # Test app OAuth returns to a different port
    ENV['GITHUB_KEY'] = ENV['TEST_GITHUB_KEY']
    ENV['GITHUB_SECRET'] = ENV['TEST_GITHUB_SECRET']
  end
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'],
           scope: 'user:email, read:org'
  Hashie.logger = Rails.logger
end
