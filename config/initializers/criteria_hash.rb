# frozen_string_literal: true
require 'yaml'
# Load in entire criteria.yml, which keys off the major/minor groups
FullCriteriaHash = YAML.load_file('criteria.yml').with_indifferent_access.freeze
criteria_hash = {}.with_indifferent_access
FullCriteriaHash.each do |major, major_value|
  major_value.each do |minor, criteria|
    criteria.each do |criterion_key, criterion_data|
      criteria_hash[criterion_key] = criterion_data
      criteria_hash[criterion_key][:major] = major
      criteria_hash[criterion_key][:minor] = minor
    end
  end
end
CriteriaHash = criteria_hash.freeze
