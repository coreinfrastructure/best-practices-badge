# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'yaml'
# Load in entire criteria.yml, which keys off the major/minor groups
# NOTE: Using YAML.safe_load_file for security
metal_criteria = YAML.safe_load_file(
  'criteria/criteria.yml',
  permitted_classes: [Symbol],
  aliases: true
)

# Load baseline criteria if file exists
baseline_file = 'criteria/baseline_criteria.yml'
begin
  if File.exist?(baseline_file)
    baseline_criteria = YAML.safe_load_file(
      baseline_file,
      permitted_classes: [Symbol],
      aliases: true
    )
    # Remove metadata key before merging (it's not a criteria level)
    baseline_criteria.delete('_metadata')
    # Merge baseline criteria into metal criteria
    FullCriteriaHash = metal_criteria.merge(baseline_criteria).with_indifferent_access.freeze
  else
    FullCriteriaHash = metal_criteria.with_indifferent_access.freeze
  end
rescue Errno::ENOENT
  # Handle race condition if file is deleted between exist? check and load
  FullCriteriaHash = metal_criteria.with_indifferent_access.freeze
end

criteria_hash = {}.with_indifferent_access
FullCriteriaHash.each do |level, level_value|
  next if level == '_metadata' # Skip metadata entry from baseline criteria

  criteria_hash[level] = {}.with_indifferent_access
  level_value.each do |major, major_value|
    major_value.each do |minor, criteria|
      criteria.each do |criterion_key, criterion_data|
        # For baseline criteria, filter out fields not recognized by Criteria model
        # Description/details/placeholders are loaded from locale files via i18n
        # Baseline-specific metadata fields are also filtered out
        filtered_data = criterion_data.dup
        if level.to_s.start_with?('baseline-')
          # Remove i18n fields (loaded from locale files)
          filtered_data.delete('description')
          filtered_data.delete('details')
          filtered_data.delete('met_placeholder')
          filtered_data.delete('unmet_placeholder')
          filtered_data.delete('na_placeholder')
          # Remove baseline-specific metadata fields
          filtered_data.delete('external_id')
          filtered_data.delete('baseline_id')
          filtered_data.delete('baseline_maturity_levels')
          filtered_data.delete('external_mappings')
          filtered_data.delete('original_id')
        end

        criteria_hash[level][criterion_key] = filtered_data
        criteria_hash[level][criterion_key][:major] = major
        criteria_hash[level][criterion_key][:minor] = minor
      end
    end
  end
end

CriteriaHash = criteria_hash.freeze
