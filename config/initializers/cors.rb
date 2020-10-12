# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Allow client-side JavaScript of other systems to make GET requests,
# but *only* get requests, from us.  We do *not* share credentials.

# Typically CORS users will request the JSON files, e.g., by using
# using the suffix ".json" on the resource. We do allow requests to
# some non-JSON resources, in case it's useful.

# There are some complications in the interaction of CORS and the
# HTTP Heading 'Vary'.  For more information, see:
# https://www.fastly.com/blog/best-practices-using-vary-header
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept

# It should be fine to allow "GET" and "OPTIONS" on any request,
# since we require credentials for anything non-public.  However,
# we only allow CORS access for specific resources, out of an abundance
# of caution.  We allow "/" just to make testing easy.
# It's really "GET" that we want to allow, but we allow OPTIONS
# in case a web browser decides to make a pre-flight request.

CORS_ALLOWED_METHODS = %i[get options].freeze

# Many resources we allow CORS requests for *might* differ depending on
# who is asking. In these cases were use the default CORS value for
# the HTTP Header 'Vary', which is 'Accept-Encoding, Origin':
# * 'Accept-Encoding' is necessary because different browsers accept
# different compression algorithms. Fastly normalizes this when we pass
# it through Fastly, so this doesn't have a negative impact.
# * 'Origin' is often necessary for security. In some cases we vary the output
# depending on rights of the requestor. The browser would cache that.
# If JavaScript from another origin then requested the same data, and
# the 'Origin' was not included, the browser might return the cached
# result (even though the origin might not have the same rights).
#
# This does mean different origins cannot share any caches.
#
# We do not include 'Accept' in the default Vary setting in CORS.
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

CORS_DIFFERENTIATED_RESOURCE_PATTERNS = [
  '/projects', '/projects.json', '/projects/*',
  '/projects/**/*', '/project_stats*',
  '/en/projects', '/en/projects.json', '/en/projects/*',
  '/en/projects/**/*', '/en/project_stats*',
  '/users/*.json', '/en/users/*.json'
].freeze

# For some resources we are absolutely *certain* that their results
# are undifferentiated, no matter who requests it or what its origin is.
# This is, in particular, true for /projects/:id/badges(.json).
# In this case Vary only includes Accept-Encoding, and *not* an Origin.
# Out of an abundance of caution we only include resources if we are
# *certain* about this. It's true for badges (SVG/JSON), and that's the
# important case because we want to ensure that the CDN can share them
# across all users. By omitting "Origin" for these, we significantly
# optimize use because any Origin will share the same CDN cache entry.
#
# Note: we don't need to include 'Accept' in the HTTP Header 'Vary' for
# /projects/:id/badge(.:format) resource because we *always* ignored
# the HTTP 'Accept' heading for selecting its data format (due to
# the way it gets routed). This is the most important case
# (because the CDN cache is shared globally); the fewer things we can
# put in 'Vary' for this important (highly optimized) case, the better.
#
# Note: This cannot be exploited to be misinterpreted as something else.
# The "*" does not match an embedded "/". Even if an attacker used "..",
# that would just produce the useless "/badge" and "/badge.json".

CORS_UNDIFFERENTIATED_RESOURCE_PATTERNS = [
  '/projects/*/badge', '/projects/*/badge.json'
].freeze
CORS_UNDIFFERENTIATED_VARY = ['Accept-Encoding'].freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    # "credentials" is false (not sent) by default.

    # 'Vary' does NOT include the Origin in undifferentiated resources.
    # In these cases the same result must always occur.
    # These undifferentiated rules must be first so they have higher priority.
    CORS_UNDIFFERENTIATED_RESOURCE_PATTERNS.each do |resource_pattern|
      resource resource_pattern, headers: :any, methods: CORS_ALLOWED_METHODS,
               vary: CORS_UNDIFFERENTIATED_VARY
    end

    # 'Vary' is the default, includes Origin.
    CORS_DIFFERENTIATED_RESOURCE_PATTERNS.each do |resource_pattern|
      resource resource_pattern, headers: :any, methods: CORS_ALLOWED_METHODS
    end
  end
end
