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

  def analyze(_evidence, current)
    homepage_url = current[:homepage_url]
    repo_url = current[:repo_url]
    @results = {}

    http_pattern = %r{\Ahttp://}i
    if homepage_url =~ http_pattern || repo_url =~ http_pattern
      set_http_results(repo_url, http_pattern)
    elsif homepage_url.present? || repo_url.present?
      https_pattern = %r{\Ahttps://}i
      set_https_results if homepage_url =~ https_pattern ||
                           repo_url =~ https_pattern
    end
    @results
  end

  private

  # rubocop:disable Metrics/MethodLength
  def set_http_results(repo_url, http_pattern)
    @results[:sites_https_status] =
      {
        value: CriterionStatus::UNMET, confidence: 5,
        explanation: '// Given an http: URL.'
      }
    # Any official channel using http is a problem
    @results[:osps_br_03_01_status] =
      {
        value: CriterionStatus::UNMET, confidence: 5,
        explanation: 'Project URLs lists http (not https) as official.'
      }
    # Distribution channels: only repo_url is a distribution channel,
    # homepage_url alone should not trigger UNMET.
    return unless repo_url&.match?(http_pattern)

    @results[:osps_br_03_02_status] =
      {
        value: CriterionStatus::UNMET, confidence: 5,
        explanation: 'Repository URL uses http (not https).'
      }
  end
  # rubocop:enable Metrics/MethodLength

  def met_result(explanation)
    { value: CriterionStatus::MET, confidence: 3, explanation: explanation }
  end

  def set_https_results
    @results[:sites_https_status] = met_result('Given only https: URLs.')
    @results[:osps_br_03_01_status] =
      met_result('Project URLs use HTTPS exclusively.')
    @results[:osps_br_03_02_status] =
      met_result('Distribution channels use HTTPS exclusively.')
  end
end
