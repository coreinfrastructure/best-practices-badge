# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# MappingDetective - Abstract base class for criterion-mapping detectives.
# Subclasses translate answers from one set of criteria (source) to proposed
# answers for another set (target) using a YAML-defined confidence map.
#
# Subclasses must define:
#   MAPPINGS - Array of mapping hashes loaded from a YAML file via load_mappings
#   INPUTS   - Source criterion _status fields (derived from MAPPINGS)
#   OUTPUTS  - Target criterion _status fields (derived from MAPPINGS)
#
# MappingDetective subclasses are treated specially by Chief: they are
# partitioned out of the normal detective pool (see Chief#partition_mapping_detective)
# and exactly one is selected and run explicitly late, after all other detectives,
# so it benefits from fully-accumulated proposals in the current_proposal hash.
class MappingDetective < Detective
  INPUTS = [].freeze
  OUTPUTS = [].freeze
  OVERRIDABLE_OUTPUTS = [].freeze
  MAPPINGS = [].freeze

  # Load a YAML mapping file and return the 'mappings' array.
  # Called at class definition time in subclasses.
  # @param file [String] path relative to Rails.root
  # @return [Array<Hash>] array of mapping hashes
  def self.load_mappings(file)
    YAML.safe_load_file(
      Rails.root.join(file),
      permitted_classes: [],
      aliases: true
    )['mappings']
  end

  # Translate source criterion answers to target criterion proposals.
  # Source values are read from +current+, which Chief populates via
  # compute_current(INPUTS, project, current_proposal) — providing the
  # best available value for each source field (accumulated proposal or
  # original project value). Justification text is read from evidence.project.
  #
  # FUTURE ENHANCEMENT — confidence scaling for auto-detected source values:
  # When a source field was auto-detected by a prior detective at confidence C,
  # the mapping confidence should arguably be scaled down: C * (mapping_conf / 5).
  # This prevents a low-confidence detection from being promoted to a higher
  # mapping confidence. For user-entered values (read from evidence.project
  # directly) the source confidence would be treated as 5 (authoritative).
  # Currently, compute_current strips confidence and passes only the value, so
  # this class has no access to source confidence.
  # To implement: pass current_proposal (or its confidence slice) as a third
  # argument to analyze, look up source confidence in resolve_confidence, and
  # multiply: scaled = (source_conf * mapping_conf / Chief::MAX_CONFIDENCE).round
  # The change stays entirely within MappingDetective and Chief#propose_one_change
  # (or a dedicated MappingDetective override); no other detective class is affected.
  #
  # @param evidence [Evidence] project evidence wrapper; used for justification
  # @param current [Hash] current best estimates for INPUTS fields
  # @return [Hash] proposed target criterion _status values
  # rubocop:disable Metrics/MethodLength
  def analyze(evidence, current)
    return {} if evidence.nil?

    project = evidence.project
    results = {}

    self.class::MAPPINGS.each do |mapping|
      source_criterion = mapping['source_criterion']
      target_criterion = mapping['target_criterion']

      source_status = current[:"#{source_criterion}_status"]
      confidence, target_status = resolve_confidence(mapping, source_status)
      next if confidence.zero?

      target_field = :"#{target_criterion}_status"
      next if results.key?(target_field) &&
              confidence <= results[target_field][:confidence]

      results[target_field] = {
        value: target_status,
        confidence: confidence,
        explanation: build_explanation(project, source_criterion)
      }
    end

    results
  end
  # rubocop:enable Metrics/MethodLength

  private

  # Determine inference confidence and target status from a mapping entry
  # and the source criterion's current status.
  #
  # Each confidence field in the YAML is either:
  #   - An integer (0-3): same-status inference (target gets same status as source)
  #   - A [confidence, "StatusName"] array: cross-status inference
  #
  # @param mapping [Hash] a single mapping entry from the YAML
  # @param source_status [Integer, nil] source criterion status integer
  # @return [Array(Integer, Integer)] [confidence (0-3), target_status integer]
  #   confidence 0 means "no inference; skip this entry"
  # rubocop:disable Metrics/MethodLength
  def resolve_confidence(mapping, source_status)
    conf_key =
      case source_status
      when CriterionStatus::MET   then 'confidence_met'
      when CriterionStatus::UNMET then 'confidence_unmet'
      when CriterionStatus::NA    then 'confidence_na'
      else return [0, nil]
      end

    spec = mapping[conf_key]
    return [0, nil] if spec.nil?

    if spec.is_a?(Array)
      confidence = spec.first
      target_status = CriterionStatus.parse(spec[1])
    else
      confidence = spec
      target_status = source_status
    end
    return [0, nil] if confidence.zero?

    [confidence, target_status]
  end
  # rubocop:enable Metrics/MethodLength

  # Build the explanation string for a proposed target criterion.
  # Carries over the source criterion's justification text (if any),
  # appending the source criterion name in brackets as attribution.
  #
  # Uses has_attribute? to guard against source justification fields that
  # were not included in a partial SELECT query (e.g., when editing a
  # metal-level page, baseline justification columns are not loaded).
  # Test stubs that lack has_attribute? use [] directly (returns nil
  # for missing keys, which .to_s.strip safely converts to '').
  #
  # @param project [Project] the ActiveRecord project
  # @param source_criterion [String] source criterion name
  # @return [String] explanation text
  def build_explanation(project, source_criterion)
    justification_key = :"#{source_criterion}_justification"
    existing =
      if project.respond_to?(:has_attribute?) && !project.has_attribute?(justification_key)
        ''
      else
        project[justification_key].to_s.strip
      end
    existing.empty? ? "[#{source_criterion}]" : "#{existing} [#{source_criterion}]"
  end
end
