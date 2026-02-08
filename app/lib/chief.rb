# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# A 'chief' instance analyzes project data.  It does this by calling
# 'Detectives' (analyzers) in the right order, each of which have
# access to the evidence accumulated so far.

# Only the 'chief' decides when to update the proposed changes.
# Currently it just runs sequentially, but the plan is for it to use
# the Detective INPUTS and OUTPUTS to determine what order to run, and
# run them in parallel in an appropriate order.

# rubocop:disable Metrics/ClassLength
class Chief
  # Confidence level (1..5) where automation result will *override*
  # the status value provided by humans.
  # If the confidence is lower than this, we'll only override status '?'.
  CONFIDENCE_OVERRIDE = 4

  # TODO: Identify classes automatically and do topological sort.
  # Automatically discover all Detective subclasses from app/lib/*_detective.rb
  # This prevents the footgun of forgetting to register new detectives.
  def self.discover_detectives
    # Load all detective files from app/lib (not test/)
    detective_files = Dir[Rails.root.join('app/lib/*_detective.rb')]
    detective_files.each { |file| require_dependency file }
    
    # Get all Detective subclasses
    all_detectives = Detective.descendants
    
    # Filter to only classes defined in app/lib files (not test fixtures)
    # Check if the class is defined in a file under app/lib
    result = all_detectives.select do |detective_class|
      # Get the source location of the class
      source_file = Object.const_source_location(detective_class.name)&.first
      next false unless source_file
      
      # Only include if defined in app/lib
      source_file.include?('/app/lib/') &&
        # Exclude Test* detectives unless in test environment
        (Rails.env.test? || !detective_class.name.start_with?('Test'))
    end
    
    result
  end

  ALL_DETECTIVES = discover_detectives.freeze

  # List fields allowed to be written into Project (an ActiveRecord).
  ALLOWED_FIELDS = Project::PROJECT_PERMITTED_FIELDS.to_set.freeze

  # rubocop:disable Style/ConditionalAssignment
  def initialize(project, client_factory, entry_locale: nil)
    @evidence = Evidence.new(project)
    @client_factory = client_factory
    @entry_locale = entry_locale || project.entry_locale

    # Determine what exceptions to intercept - if we're in
    # test or development, we will only intercept an exception we don't use.
    current_environment = (ENV['RAILS_ENV'] || 'development').to_sym
    if %i[test development].include?(current_environment)
      @intercept_exception = NoSuchException
    else
      @intercept_exception = StandardError
    end
  end
  # rubocop:enable Style/ConditionalAssignment

  # Given two changesets, produce merged "best" version
  # When confidence is the same, c1 wins.
  # Adds a :forced flag based on confidence level (internal detail not exposed)
  def merge_changeset(c1, c2)
    result = c1.dup
    c2.each do |field, data|
      next if result.key?(field) &&
              (data[:confidence] <= result[field][:confidence])

      # Add forced flag based on confidence (hide confidence from callers)
      enhanced_data = data.dup
      enhanced_data[:forced] =
        data[:confidence].present? && data[:confidence] >= CONFIDENCE_OVERRIDE
      result[field] = enhanced_data
    end
    result
  end

  # Should we should update a project's value for 'key'?
  # changeset_data is hash with :value, :confidence, :explanation
  def update_value?(project, key, changeset_data)
    if changeset_data.blank?
      false
    elsif !project.attribute_present?(key) || project[key].blank? ||
          project[key] == CriterionStatus::UNKNOWN
      true
    else
      changeset_data[:confidence].present? &&
        changeset_data[:confidence] >= CONFIDENCE_OVERRIDE
    end
  end

  # Return the best estimates for fields, given project & current proposal.
  # Current proposal is a hash, keys are symbols of what that might be changed.
  def compute_current(fields, project, current_proposal)
    result = {}
    fields.each do |f|
      if update_value?(project, f, current_proposal[f])
        result[f] = current_proposal[f][:value]
      elsif project.attribute_present?(f)
        result[f] = project[f]
      end
    end
    result
  end

  def log_detective_failure(source, e, detective, proposal, data)
    Rails.logger.error do
      'ERROR:: ' \
        "In method #{source}, exception #{e} on #{detective.class.name}, " \
        "current_proposal= #{proposal}, current_data= #{data}"
    end
  end

  # Invoke one "Detective", which will
  # analyze the project and reply with an updated changeset in the form
  # { fieldname1: { value: value, confidence: 1..5, explanation: text}, ...}
  # rubocop:disable Metrics/MethodLength
  def propose_one_change(detective, current_proposal)
    begin
      current_data = compute_current(
        detective.class::INPUTS, @evidence.project, current_proposal
      )
      result = detective.analyze(@evidence, current_data)
      current_proposal = merge_changeset(current_proposal, result)
    # If we're in production, ignore exceptions from detectives.
    # That way we just autofill less, instead of completely failing.
    rescue @intercept_exception => e
      log_detective_failure(
        'propose_one_change', e, detective, current_proposal, current_data
      )
    end
    current_proposal
  end
  # rubocop:enable Metrics/MethodLength

  # Determine which detectives are needed to produce the requested outputs.
  # Uses backward search from needed_outputs through detective dependency graph.
  # @param needed_outputs [Set] Set of field symbols we want to produce
  # @return [Array<Class>] Array of detective classes needed
  # rubocop:disable Metrics/MethodLength
  def filter_needed_detectives(needed_outputs)
    return ALL_DETECTIVES if needed_outputs.blank?

    required_detectives = Set.new
    required_outputs = needed_outputs.dup
    changed = true

    # Backward search: keep adding detectives whose outputs we need
    while changed
      changed = false
      ALL_DETECTIVES.each do |detective_class|
        next if required_detectives.include?(detective_class)

        # If this detective provides any output we need, include it
        # Use set intersection to check overlap
        next unless detective_class::OUTPUTS.to_set.intersect?(required_outputs)

        required_detectives.add(detective_class)
        # Now we also need its inputs
        required_outputs.merge(detective_class::INPUTS)
        changed = true
      end
    end

    required_detectives.to_a
  end
  # rubocop:enable Metrics/MethodLength

  # Sort detectives in topological order based on their INPUTS/OUTPUTS.
  # Uses Kahn's algorithm for topological sort.
  # @param detectives [Array<Class>] Detective classes to sort
  # @return [Array<Class>] Sorted detective classes
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def topological_sort_detectives(detectives)
    # Build dependency graph: detective => Set of detectives it depends on
    dependencies = {}
    detectives.each do |detective_class|
      dependencies[detective_class] = Set.new

      # For each detective, find which other detectives it depends on
      inputs_needed = detective_class::INPUTS.to_set
      detectives.each do |other_detective|
        next if detective_class == other_detective

        # If other_detective provides outputs that detective_class needs as inputs
        outputs_provided = other_detective::OUTPUTS.to_set
        if outputs_provided.intersect?(inputs_needed)
          dependencies[detective_class].add(other_detective)
        end
      end
    end

    # Kahn's algorithm for topological sort
    sorted = []
    no_dependencies = detectives.select { |d| dependencies[d].empty? }

    until no_dependencies.empty?
      detective = no_dependencies.shift
      sorted << detective

      # Remove this detective from all dependency lists
      dependencies.each do |dependent, deps|
        deps.delete(detective)
        no_dependencies << dependent if deps.empty? && !sorted.include?(dependent)
      end
    end

    # If not all detectives are sorted, there's a circular dependency
    # Fall back to original order for safety
    sorted.size == detectives.size ? sorted : detectives
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Determine which output fields are needed based on the badge level.
  # @param level [String, nil] Badge level ('passing', 'silver', 'gold',
  #   'baseline-1', 'baseline-2', 'baseline-3') or nil for all criteria
  # @param changed_fields [Array<Symbol>, nil] Additional fields that were changed
  # @return [Set<Symbol>] Set of field symbols needed
  # rubocop:disable Metrics/MethodLength
  def needed_outputs_for_level(level, changed_fields = nil)
    needed = Set.new

    # If level is nil, we need everything (cron job scenario)
    if level.nil?
      ALL_DETECTIVES.each { |d| needed.merge(d::OUTPUTS) }
      return needed
    end

    # Add outputs for fields in this level
    # Note: This is a simplified version. Real implementation would query
    # Criteria.active(level) to get the actual criteria for this level.
    # For now, we'll use a heuristic based on field name patterns.
    case level
    when 'passing', 'silver', 'gold'
      # Metal series - fields without osps_ prefix
      ALL_DETECTIVES.each do |detective_class|
        detective_class::OUTPUTS.each do |output|
          needed.add(output) unless output.to_s.start_with?('osps_')
        end
      end
    when 'baseline-1', 'baseline-2', 'baseline-3'
      # Baseline series - fields with osps_ prefix
      ALL_DETECTIVES.each do |detective_class|
        detective_class::OUTPUTS.each do |output|
          needed.add(output) if output.to_s.start_with?('osps_')
        end
      end
    end

    # Add any explicitly changed fields (for save scenario)
    needed.merge(changed_fields) if changed_fields

    needed
  end
  # rubocop:enable Metrics/MethodLength

  # Analyze project and reply with a changeset in the form
  # { fieldname1: { value: value, confidence: 1..5, explanation: text}, ...}
  # Do this by determining the right order and way to invoke "detectives"
  # for this project, invoke them, and process their results.
  # @param level [String, nil] Badge level to analyze (nil = all)
  # @param changed_fields [Array<Symbol>, nil] Fields that were explicitly changed
  # rubocop:disable Metrics/MethodLength
  def propose_changes(level: nil, changed_fields: nil)
    current_proposal = {} # Current best changeset.

    # Determine what outputs we need based on level and changed fields
    needed = needed_outputs_for_level(level, changed_fields)

    # Filter to only needed detectives (subset varies per request)
    detectives_to_run = filter_needed_detectives(needed)

    # Sort that specific subset in dependency order
    detectives_to_run = topological_sort_detectives(detectives_to_run)

    # Run each detective in the sorted order
    detectives_to_run.each do |detective_class|
      detective = detective_class.new
      detective.octokit_client_factory = @client_factory
      current_proposal = propose_one_change(detective, current_proposal)
    end
    current_proposal
  end
  # rubocop:enable Metrics/MethodLength

  # Given project data, return it with the proposed changeset applied.
  # Note: This should probably be class-level
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def apply_changes(project, changes)
    changes.each do |key, data|
      next if ALLOWED_FIELDS.exclude?(key)
      next unless update_value?(project, key, data)

      # Store change:
      project[key] = data[:value]
      # Now add the explanation, if we can.
      next unless key.to_s.end_with?('_status') && data.key?(:explanation)

      justification_key = (key.to_s.chomp('_status') + '_justification').to_sym
      if project.attribute_present?(justification_key)
        unless project[justification_key].end_with?(data[:explanation])
          project[justification_key] =
            project[justification_key] + ' ' + data[:explanation]
        end
      else
        project[justification_key] = data[:explanation]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # Given form data about a project, return an improved version.
  # @param level [String, nil] Badge level to analyze (nil = all)
  # @param changed_fields [Array<Symbol>, nil] Fields that were explicitly changed
  def autofill(level: nil, changed_fields: nil)
    my_proposed_changes = propose_changes(level: level, changed_fields: changed_fields)
    apply_changes(@evidence.project, my_proposed_changes)
  end
end
# rubocop:enable Metrics/ClassLength
