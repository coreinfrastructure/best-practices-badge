# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Determine if project sites support HTTPS

class HardenedSitesDetective < Detective
  # Field name, must be in lowercase.
  XCTO = 'x-content-type-options'

  # The sole allowed value for the X-Content-Type-Options header.
  NOSNIFF = 'nosniff'

  # All of the security-hardening headers that need to be present to pass.
  # They're listed in the same order as the criteria text.
  # Field names must be in lowercase here.
  CHECK =
    [
      'content-security-policy', 'strict-transport-security',
      XCTO, 'x-frame-options'
    ].freeze
  MET =
    {
      value: 'Met', confidence: 3,
      explanation: 'Found all required security hardening headers.'
    }.freeze
  UNMET_MISSING =
    {
      value: 'Unmet', confidence: 5,
      explanation: '// One or more of the required security hardening headers ' \
                   'is missing.'
    }.freeze
  UNMET_NOSNIFF =
    {
      value: 'Unmet', confidence: 5,
      explanation: '// X-Content-Type-Options was not set to "nosniff".'
    }.freeze

  INPUTS = %i[repo_url homepage_url].freeze
  OUTPUTS = [:hardened_site_status].freeze

  # Check the given list of header hashes to make sure that all expected
  # keys are present.
  def security_fields_present?(headers_list)
    result = true
    headers_list.each do |headers|
      result &&= CHECK.reduce(true) { |acc, elem| acc & headers.key?(elem) }
    end
    result
  end

  # Perform GET request, and return either an empty hash (if the GET is
  # unsuccessful) or a hash of the HTTP response header keys and values.
  # Note: in the returned hash all field names are ASCII *lowercase*, so that
  # we can easily do case-insensitive matches (HTTP field names are
  # case-insensitive, see RFC 2616 section 4.2).
  def get_headers(evidence, url)
    response = evidence.get(url)
    results = response.nil? ? {} : response[:meta]
    # Return a version with keys in lowercase; we do *not* modify the original.
    # We use ":ascii" so that Turkic locales don't cause oddities. That
    # shouldn't matter anyway, since the user's locale is in I18n.locale,
    # but it's safer to be defensive.
    results.transform_keys { |k| k.to_s.downcase(:ascii) }
  end

  # Inspect the X-Content-Type-Options headers and make sure that they have the
  # only allowed value.
  def check_nosniff?(headers_list)
    result = true
    headers_list.each do |response_headers|
      xcto = response_headers[XCTO]
      result &&= xcto.nil? ? false : xcto.casecmp(NOSNIFF).zero?
    end
    result
  end

  # Internal method that does the inspection work for the 'analyze' method.
  def check_urls(evidence, homepage_url, repo_url)
    @results = {}
    # Only complain if we have *both* a homepage_url AND repo_url.
    # When that isn't true other criteria will catch it first.
    if homepage_url.present? && repo_url.present?
      homepage_headers = get_headers(evidence, homepage_url)
      repo_headers = get_headers(evidence, repo_url)
      hardened = security_fields_present?([homepage_headers, repo_headers])
      @results[:hardened_site_status] = hardened ? MET : UNMET_MISSING
      hardened ||= check_nosniff?([homepage_headers, repo_headers])
      @results[:hardened_site_status] = UNMET_NOSNIFF unless hardened
    end
    @results
  end

  # Analyze the home page and repository URLs to make sure that security
  # hardening headers are returned in the headers of a GET response.
  def analyze(evidence, current)
    check_urls(evidence, current[:homepage_url], current[:repo_url])
  end
end
