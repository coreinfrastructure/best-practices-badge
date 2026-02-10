# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Baseline Detective - Handles baseline-specific automated checks that don't
# have equivalents in the metal series. Most baseline automation is handled by
# extending existing detectives (FlossLicenseDetective, ProjectSitesHttpsDetective,
# etc.) to output both metal and baseline fields from a single analysis.
#
# This detective only handles truly baseline-unique checks like SECURITY.md
# file detection.
class BaselineDetective < Detective
  # We need repo_files to check for baseline-specific files
  INPUTS = [:repo_files].freeze

  # Baseline criteria that are unique to baseline (not checked by metal series)
  OUTPUTS = %i[
    osps_gv_02_01_status osps_gv_03_01_status osps_le_02_01_status
  ].freeze

  # This detective can override baseline-specific criteria with high confidence
  OVERRIDABLE_OUTPUTS = %i[].freeze

  # Analyze project evidence and return changeset for baseline-unique criteria
  def analyze(_evidence, current)
    result = {}

    # Security policy (osps_gv_02_01, osps_gv_03_01) - unique to baseline
    check_security_policy(result, current)

    # License declaration (osps_le_02_01) - check if license field is populated
    check_license_declaration(result, current)

    result
  end

  private

  # Check osps_gv_02_01 and osps_gv_03_01: Security/vulnerability disclosure
  def check_security_policy(result, current)
    return if current[:repo_files].blank?

    security_file = find_security_file(current[:repo_files])
    return unless security_file

    add_security_policy_results(result, security_file)
  end

  # Add security policy results to the changeset
  def add_security_policy_results(result, security_file)
    result[:osps_gv_02_01_status] = {
      value: 'Met',
      confidence: 3,
      explanation: "Security policy found: #{security_file['name']}."
    }

    result[:osps_gv_03_01_status] = {
      value: 'Met',
      confidence: 3,
      explanation: 'Security policy file suggests vulnerability reporting ' \
                   'process is documented.'
    }
  end

  # Check osps_le_02_01: License must be declared
  # Note: license file detection is handled by RepoFilesExamineDetective
  def check_license_declaration(result, current)
    return if current[:license].blank?
    return if %w[NOASSERTION NONE].include?(current[:license])

    result[:osps_le_02_01_status] = {
      value: 'Met',
      confidence: 3,
      explanation: "License declared: #{current[:license]}."
    }
  end

  # Find SECURITY.md or similar security policy file
  def find_security_file(repo_files)
    return unless repo_files.respond_to?(:get_info)

    top_level = repo_files.get_info('/')
    return unless top_level.is_a?(Array)

    top_level.find do |file|
      file.is_a?(Hash) &&
        file['type'] == 'file' &&
        file['name']&.match?(/\ASECURITY(\.md|\.txt)?\z/i)
    end
  end
end
