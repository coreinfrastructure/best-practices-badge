# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'yaml'
require 'json'

# Validates baseline criteria and mapping files
class BaselineCriteriaValidator
  attr_reader :errors

  def initialize
    @criteria_file = Rails.root.join(BASELINE_CONFIG[:criteria_file])
    @mapping_file = Rails.root.join(BASELINE_CONFIG[:mapping_file])
    @errors = []
  end

  # These are command methods that perform validation and modify state (@errors),
  # not pure predicate methods. The naming follows validation command conventions.
  # rubocop:disable Naming/PredicateMethod
  def validate
    @errors = []

    validate_criteria_file_exists
    validate_criteria_yaml_valid
    validate_mapping_file_exists if File.exist?(@mapping_file)

    @errors.empty?
  end

  private

  def validate_criteria_file_exists
    unless File.exist?(@criteria_file)
      @errors << "Criteria file not found: #{@criteria_file}"
      return false
    end
    true
  end

  def validate_criteria_yaml_valid
    return false unless validate_criteria_file_exists

    YAML.safe_load_file(
      @criteria_file,
      permitted_classes: [Symbol],
      aliases: true
    )
    true
  rescue Psych::SyntaxError => e
    @errors << "Invalid YAML in #{@criteria_file}: #{e.message}"
    false
  end

  def validate_mapping_file_exists
    unless File.exist?(@mapping_file)
      @errors << "Mapping file not found: #{@mapping_file}"
      return false
    end

    begin
      JSON.parse(File.read(@mapping_file))
      true
    rescue JSON::ParserError => e
      @errors << "Invalid JSON in #{@mapping_file}: #{e.message}"
      false
    end
  end
  # rubocop:enable Naming/PredicateMethod
end
