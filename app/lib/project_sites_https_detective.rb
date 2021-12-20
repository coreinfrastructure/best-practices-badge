# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Determine if project sites support HTTPS

class ProjectSitesHttpsDetective < Detective
  INPUTS = %i[repo_url homepage_url].freeze
  OUTPUTS = [:sites_https_status].freeze

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def analyze(_evidence, current)
    homepage_url = current[:homepage_url]
    repo_url = current[:repo_url]
    @results = {}

    https_pattern = %r{\Ahttps://}i
    http_pattern = %r{\Ahttp://}i

    if homepage_url =~ http_pattern || repo_url =~ http_pattern
      @results[:sites_https_status] =
        {
          value: 'Unmet', confidence: 5,
          explanation: '// Given an http: URL.'
        }
    elsif homepage_url.blank? && repo_url.blank?
      # Do nothing.  Shouldn't happen.
    elsif homepage_url =~ https_pattern || repo_url =~ https_pattern
      @results[:sites_https_status] =
        {
          value: 'Met', confidence: 3,
          explanation: 'Given only https: URLs.'
        }
    end
    @results
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
