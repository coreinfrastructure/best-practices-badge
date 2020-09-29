# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Allow client-side JavaScript of other systems to make GET requests,
# but *only* get requests, from us.  We do *not* share credentials.

# It should be fine to allow "GET" and "OPTIONS" on any request,
# since we require credentials for anything non-public.  However,
# we only allow CORS access for specific resources, out of an abundance
# of caution.  We allow "/" just to make testing easy.
# It's really "GET" that we want to allow, but we allow OPTIONS
# in case a web browser decides to make a pre-flight request.
# Typically CORS users will request the JSON files, e.g., by using
# using the suffix ".json" on the resource.

CORS_ALLOWED_METHODS = %i[get options].freeze
CORS_RESOURCE_PATTERNS = [
  '/projects', '/projects.json', '/projects/*',
  '/projects/**/*', '/project_stats*',
  '/en/projects', '/en/projects.json', '/en/projects/*',
  '/en/projects/**/*', '/en/project_stats*',
  '/users/*.json', '/en/users/*.json'
].freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    # "credentials" is false (not sent) by default.
    CORS_RESOURCE_PATTERNS.each do |resource_pattern|
      resource resource_pattern, headers: :any, methods: CORS_ALLOWED_METHODS
    end
  end
end
