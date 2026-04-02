# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# SecurityInsightsDetective - infers badge criteria answers from a project's
# security-insights.yml file (OSSF Security Insights spec).
#
# The file is looked up in the repository root and .github/ directory.
# Mappings from security-insights fields to badge criteria are defined in
# criteria/security_insights_map.yml.
# To refresh the # Target: criterion-text comments in that file, run:
#   ruby script/update_security_insights_comments.rb
#
# SECURITY: The security-insights.yml file is untrusted data.
# - File size is capped at MAX_SI_SIZE bytes before fetching.
# - YAML is loaded with safe_load (no Ruby objects) and aliases disabled
#   (prevents YAML alias/anchor bombs).
# - All path navigation and condition evaluation defensively checks types.
# rubocop:disable Metrics/ClassLength
class SecurityInsightsDetective < Detective
  # Maximum size of a security-insights file we will fetch and parse.
  # 50 KB is generous; real files are typically a few kilobytes.
  MAX_SI_SIZE = 50_000

  # Candidate file paths to check, in priority order.
  SI_CANDIDATE_PATHS = %w[
    security-insights.yml
    SECURITY-INSIGHTS.yml
    .github/security-insights.yml
    .github/SECURITY-INSIGHTS.yml
  ].freeze

  MAPPINGS = YAML.safe_load_file(
    Rails.root.join('criteria/security_insights_map.yml'),
    permitted_classes: [],
    aliases: false
  )['mappings'].freeze

  INPUTS  = [:repo_files].freeze
  OUTPUTS = MAPPINGS.map { |m| :"#{m['target_criterion']}_status" }.uniq.freeze
  OVERRIDABLE_OUTPUTS = [].freeze

  # Analyze the project's security-insights.yml file and propose criterion values.
  # @param _evidence [Evidence] unused
  # @param current [Hash] must contain :repo_files
  # @return [Hash] proposed criterion status changes
  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    content, location = find_security_insights(repo_files)
    return {} if content.nil?

    si_data = parse_security_insights(content)
    return {} unless si_data.is_a?(Hash)

    evaluate_mappings(si_data, location)
  end

  private

  # Look for a security-insights file in the standard locations.
  # @param repo_files [GithubContentAccess] repo file accessor
  # @return [Array(String, String), nil] [content, path] or nil if not found
  def find_security_insights(repo_files)
    SI_CANDIDATE_PATHS.each do |path|
      content = repo_files.get_content(path, max_size: MAX_SI_SIZE)
      return [content, path] if content
    end
    nil
  end

  # Parse security-insights YAML content safely.
  # Uses safe_load with no permitted classes and aliases disabled to prevent
  # Ruby object injection and YAML alias/anchor bombs.
  # @param content [String] raw YAML text
  # @return [Object, nil] parsed YAML or nil on error
  def parse_security_insights(content)
    YAML.safe_load(
      content,
      permitted_classes: [],
      aliases: false,
      symbolize_names: false
    )
  rescue Psych::Exception
    nil
  end

  # Walk the MAPPINGS array, evaluate each condition, and collect proposals.
  # When multiple entries target the same criterion, keep the highest confidence.
  # @param si_data [Hash] parsed security-insights YAML
  # @param location [String] file path (for explanation text)
  # @return [Hash] proposed criterion status changes
  def evaluate_mappings(si_data, location)
    results = {}
    MAPPINGS.each do |mapping|
      value = dig_path(si_data, mapping['si_path'])
      next unless condition_met?(mapping, value)

      apply_mapping(results, mapping, location, value, si_data)
    end
    results
  end

  # Record one mapping's proposal into results, keeping highest confidence.
  # @param results [Hash] accumulator for proposals
  # @param mapping [Hash] one MAPPINGS entry
  # @param location [String] file path (for explanation text)
  # @param value [Object] resolved value at si_path
  # @param si_data [Hash] full parsed security-insights YAML (for comment extraction)
  def apply_mapping(results, mapping, location, value, si_data)
    target_field = :"#{mapping['target_criterion']}_status"
    confidence   = mapping['confidence']
    return if results.key?(target_field) && confidence <= results[target_field][:confidence]

    results[target_field] = {
      value:       CriterionStatus.parse(mapping['inferred_status']),
      confidence:  confidence,
      explanation: build_explanation(location, mapping, value, si_data)
    }
  end

  # Navigate a dot-separated path through a nested Hash.
  # Returns nil for any missing key or non-Hash intermediate node.
  # @param data [Object] root of the YAML tree
  # @param path [String] dot-separated key path, e.g. "repository.status"
  # @return [Object, nil] value at that path, or nil
  def dig_path(data, path)
    return unless data.is_a?(Hash) && path.is_a?(String)

    path.split('.').reduce(data) do |obj, key|
      return nil unless obj.is_a?(Hash)

      obj[key]
    end
  end

  # True if a non-nil, non-empty value is present.
  # @param value [Object] value to test
  # @return [Boolean]
  def value_present?(value)
    return false if value.nil?
    return false if value.respond_to?(:empty?) && value.empty?

    true
  end

  # Evaluate the mapping's si_condition against the resolved value.
  # Returns false for any unknown condition type (fail-safe).
  # @param mapping [Hash] one entry from MAPPINGS
  # @param value [Object] resolved value at si_path
  # @return [Boolean]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def condition_met?(mapping, value)
    condition = mapping['si_condition']
    si_value  = mapping['si_value']
    si_values = mapping['si_values']

    case condition
    when 'true'    then value == true
    when 'false'   then value == false
    when 'present' then value_present?(value)
    when 'equals'  then value.to_s == si_value.to_s
    when 'in'      then Array(si_values).include?(value.to_s)
    when 'has_tool_type'
      value.is_a?(Array) &&
        value.any? { |t| t.is_a?(Hash) && t['type'] == si_value }
    when 'has_tool_type_in_ci'
      value.is_a?(Array) &&
        value.any? do |t|
          t.is_a?(Hash) && t['type'] == si_value &&
            t.dig('integration', 'ci') == true
        end
    when 'has_attestation_predicate'
      value.is_a?(Array) &&
        value.any? { |a| a.is_a?(Hash) && a['predicate-uri'].to_s.include?(si_value.to_s) }
    else
      false
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Build a human-readable explanation string for a proposal.
  # Appends any comment found in the security-insights data for this field.
  # Uses i18n so the base message can be translated; the comment itself is not
  # translated (it is a verbatim quote from the project's own documentation).
  # @param location [String] file path where the data was found
  # @param mapping [Hash] mapping entry (for condition type and si_value)
  # @param value [Object] resolved value used in the condition
  # @param si_data [Hash] full parsed security-insights YAML
  # @return [String]
  def build_explanation(location, mapping, value, si_data)
    base    = base_explanation(File.basename(location), mapping, value)
    comment = extract_si_comment(si_data, mapping, value)
    return base unless comment

    "#{base} #{I18n.t('detectives.security_insights.comment_suffix', comment: comment)}"
  end

  # Build the base explanation before any comment suffix.
  # @param basename [String] file basename
  # @param mapping [Hash] mapping entry
  # @param value [Object] resolved value
  # @return [String]
  def base_explanation(basename, mapping, value)
    match_desc = array_match_description(mapping)
    if match_desc
      array_match_explanation(basename, mapping['si_path'], match_desc)
    else
      display_value = value.is_a?(String) ? value : value.to_s
      I18n.t('detectives.security_insights.field_value',
             location: basename, field: mapping['si_path'], value: display_value)
    end
  end

  # Return a match description string for array-type conditions, or nil.
  # @param mapping [Hash] mapping entry
  # @return [String, nil]
  def array_match_description(mapping)
    si_value = mapping['si_value']
    case mapping['si_condition']
    when 'has_tool_type'             then "type=#{si_value}"
    when 'has_tool_type_in_ci'       then "type=#{si_value} with ci=true"
    when 'has_attestation_predicate' then "predicate-uri includes #{si_value}"
    end
  end

  # Build the i18n explanation string for an array-match condition.
  # @param basename [String] file basename
  # @param si_path [String] dot-notation field path
  # @param match_desc [String] human-readable match description
  # @return [String]
  def array_match_explanation(basename, si_path, match_desc)
    I18n.t('detectives.security_insights.array_match',
           location: basename, field: si_path, match: match_desc)
  end

  # Extract an optional comment string from the security-insights data
  # relevant to this mapping's condition.
  # - Scalar conditions: looks for a "comment" key in the parent object
  #   (the object that contains the checked field).
  # - Array conditions: looks for a "comment" key in the first matching element.
  # Returns nil if no non-empty comment is found.
  # @param si_data [Hash] full parsed security-insights YAML
  # @param mapping [Hash] one MAPPINGS entry
  # @param value [Object] resolved value at si_path
  # @return [String, nil]
  def extract_si_comment(si_data, mapping, value)
    raw =
      case mapping['si_condition']
      when 'has_tool_type'
        find_tool(value, mapping['si_value'])&.dig('comment')
      when 'has_tool_type_in_ci'
        find_tool_in_ci(value, mapping['si_value'])&.dig('comment')
      when 'has_attestation_predicate'
        find_attestation(value, mapping['si_value'])&.dig('comment')
      else
        si_parent_comment(si_data, mapping['si_path'])
      end
    raw.is_a?(String) && !raw.strip.empty? ? raw.strip : nil
  end

  # Return the "comment" key of the parent object of si_path, or nil.
  # @param si_data [Hash] full parsed security-insights YAML
  # @param si_path [String] dot-notation path to the checked field
  # @return [Object, nil]
  def si_parent_comment(si_data, si_path)
    parts = si_path.split('.')
    return if parts.length < 2

    parent = dig_path(si_data, parts[0..-2].join('.'))
    parent.is_a?(Hash) ? parent['comment'] : nil
  end

  # Return the first tool in the array whose type matches, or nil.
  # @param tools [Array, Object] value at the tools si_path
  # @param type [String] tool type to match
  # @return [Hash, nil]
  def find_tool(tools, type)
    return unless tools.is_a?(Array)

    tools.find { |t| t.is_a?(Hash) && t['type'] == type }
  end

  # Return the first CI tool in the array whose type matches, or nil.
  # @param tools [Array, Object] value at the tools si_path
  # @param type [String] tool type to match
  # @return [Hash, nil]
  def find_tool_in_ci(tools, type)
    return unless tools.is_a?(Array)

    tools.find { |t| t.is_a?(Hash) && t['type'] == type && t.dig('integration', 'ci') == true }
  end

  # Return the first attestation whose predicate-uri contains the substring, or nil.
  # @param attestations [Array, Object] value at the attestations si_path
  # @param predicate_substr [String] substring to find in predicate-uri
  # @return [Hash, nil]
  def find_attestation(attestations, predicate_substr)
    return unless attestations.is_a?(Array)

    attestations.find { |a| a.is_a?(Hash) && a['predicate-uri'].to_s.include?(predicate_substr.to_s) }
  end
end
# rubocop:enable Metrics/ClassLength
