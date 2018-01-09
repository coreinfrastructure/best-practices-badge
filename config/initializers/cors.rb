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
    # It should be fine to allow "GET" and "OPTIONS" on any request,
    # since we require credentials for anything non-public.  However,
    # we only allow CORS access for specific resources, out of an abundance
    # of caution.  We allow "/" just to make testing easy.
    # It's really "GET" that we want to allow, but we allow OPTIONS
    # in case a web browser decides to make a pre-flight request.
    # Typically CORS users will request the JSON files, e.g., by using
    # using the suffix ".json" on the resource.
    ALLOWED_METHODS = %i[get options].freeze
    resource '/', headers: :any, methods: ALLOWED_METHODS
    resource '/projects', headers: :any, methods: ALLOWED_METHODS
    resource '/projects.json', headers: :any, methods: ALLOWED_METHODS
    resource '/projects/*', headers: :any, methods: ALLOWED_METHODS
    resource '/projects/**/*', headers: :any, methods: ALLOWED_METHODS
    resource '/project_stats*', headers: :any, methods: ALLOWED_METHODS
  end
end
