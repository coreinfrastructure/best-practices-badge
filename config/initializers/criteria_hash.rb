# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'yaml'
# Load in entire criteria.yml, which keys off the major/minor groups
FullCriteriaHash =
  YAML.load_file('criteria/criteria.yml').with_indifferent_access.freeze
criteria_hash = {}.with_indifferent_access
FullCriteriaHash.each do |level, level_value|
  criteria_hash[level] = {}.with_indifferent_access
  level_value.each do |major, major_value|
    major_value.each do |minor, criteria|
      criteria.each do |criterion_key, criterion_data|
        criteria_hash[level][criterion_key] = criterion_data
        criteria_hash[level][criterion_key][:major] = major
        criteria_hash[level][criterion_key][:minor] = minor
      end
    end
  end
end

CriteriaHash = criteria_hash.freeze
