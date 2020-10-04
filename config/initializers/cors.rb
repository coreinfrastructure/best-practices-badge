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

# We use the default CORS 'Vary' setting 'Accept-Encoding, Origin':
# * 'Accept-Encoding' is necessary because different browsers accept
# different compression algorithms. Fastly normalizes this when we pass
# it through Fastly, so this doesn't have a negative impact.
# * 'Origin' is necessary for security. In some cases we vary the output
# depending on rights of the requestor. The browser would cache that.
# If JavaScript from another origin then requested the same data, and
# the 'Origin' was not included, the browser might return the cached
# result (even though the origin might not have the same rights).
# This does mean that on the CDN we have separate cache entries for
# different origins, but that seems like a reasonable price to pay
# to ensure that it's secure. In the long term it'd be good to remove
# 'Origin' for /projects/NUMBER/badge(.:format), but we need to do that
# carefully to ensure that we don't leak confidential data via CORS.
#
# We do not include 'Accept' in the default CORS setting.
# In theory we should include 'Accept' sometimes, because for several
# resources the format we return varies depending on the 'Accept'
# HTTP header (e.g., if it is application/json we'll sometimes return a
# JSON format). However, we're *deprecating* using the HTTP header 'Accept'
# to select the data format.
#
# We instead want people to use different URLs for different
# output formats. This behaves *much* better with various caching systems
# in the web ecosystem. If we wanted to seriously support using 'Accept'
# for "ambiguous" URLs (which could return more than one format) then in
# those cases the controllers would need to add this:
# response.set_header('Vary', 'Accept')
# this would let browser caches know to check the 'Accept' HTTP value.
#
# Note that we don't need to consider the HTTP 'Accept' value for the
# /projects/:id/badge(.:format) because in that case we already *always*
# ignore the HTTP 'Accept' heading for selecting the data format (due to
# the way it gets routed), and that's the most important case (because that
# CDN cache is shared globally).
#
# For more information, see:
# https://www.fastly.com/blog/best-practices-using-vary-header
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    # "credentials" is false (not sent) by default.
    CORS_RESOURCE_PATTERNS.each do |resource_pattern|
      # We could add the parameter vary: ARRAY_OF_STRINGS to modify Vary.
      resource resource_pattern, headers: :any, methods: CORS_ALLOWED_METHODS
    end
  end
end
