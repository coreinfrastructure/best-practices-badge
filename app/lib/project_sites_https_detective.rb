# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Determine if project sites support HTTPS

class ProjectSitesHttpsDetective < Detective
  INPUTS = %i[repo_url homepage_url].freeze
  OUTPUTS = %i[
    sites_https_status osps_br_03_01_status osps_br_03_02_status
  ].freeze

  # This detective can override with high confidence when detecting
  # HTTP vs HTTPS usage (confidence 3-5), because http:// URL being listed
  # as an official source is a *problem*.
  OVERRIDABLE_OUTPUTS = %i[
    sites_https_status osps_br_03_01_status osps_br_03_02_status
  ].freeze

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
          value: CriterionStatus::UNMET, confidence: 5,
          explanation: '// Given an http: URL.'
        }
        # Also mark baseline criteria as unmet
      @results[:osps_br_03_01_status] =
        {
          value: CriterionStatus::UNMET, confidence: 5,
          explanation: 'Project URLs lists http (not https) as official.'
        }
      @results[:osps_br_03_02_status] =
        {
          value: CriterionStatus::UNMET, confidence: 5,
          explanation: 'Distribution channels listed as http (not https).'
        }
    elsif homepage_url.blank? && repo_url.blank?
      # Do nothing.  Shouldn't happen.
    elsif homepage_url =~ https_pattern || repo_url =~ https_pattern
      @results[:sites_https_status] =
        {
          value: CriterionStatus::MET, confidence: 3,
          explanation: 'Given only https: URLs.'
        }
      # Also mark baseline criteria as met
      @results[:osps_br_03_01_status] =
        {
          value: CriterionStatus::MET, confidence: 3,
          explanation: 'Project URLs use HTTPS exclusively.'
        }
      @results[:osps_br_03_02_status] =
        {
          value: CriterionStatus::MET, confidence: 3,
          explanation: 'Distribution channels use HTTPS exclusively.'
        }
    end
    @results
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
