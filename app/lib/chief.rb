# frozen_string_literal: true
# A 'chief' instance analyzes project data.  It does this by calling
# 'Detectives' (analyzers) in the right order, each of which have
# access to the evidence accumulated so far.

# Only the 'chief' decides when to update the proposed changes.
# Currently it just runs sequentially, but the plan is for it to use
# the Detective INPUTS and OUTPUTS to determine what order to run, and
# run them in parallel in an appropriate order.

# frozen_string_literal: true

require 'set'

# rubocop:disable Metrics/ClassLength
class Chief
  # Confidence level (1..5) where automation result will *override*
  # the status value provided by humans.
  # If the confidence is lower than this, we'll only override status '?'.
  CONFIDENCE_OVERRIDE = 4

  # rubocop:disable Style/ConditionalAssignment
  def initialize(project, client_factory)
    @evidence = Evidence.new(project)
    @client_factory = client_factory

    # Determine what exceptions to intercept - if we're in
    # test or development, we will only intercept an exception we don't use.
    current_environment = (ENV['RAILS_ENV'] || 'development').to_sym
    if %i(test development).include?(current_environment)
      @intercept_exception = NoSuchException
    else
      @intercept_exception = StandardError
    end
  end
  # rubocop:enable Style/ConditionalAssignment

  # TODO: Identify classes automatically and do topological sort.
  ALL_DETECTIVES =
    [
      NameFromUrlDetective, ProjectSitesHttpsDetective,
      GithubBasicDetective, HowAccessRepoFilesDetective,
      RepoFilesExamineDetective, FlossLicenseDetective,
      HardenedSitesDetective, BlankDetective, BuildDetective
    ].freeze

  # List fields allowed to be written into Project (an ActiveRecord).
  ALLOWED_FIELDS = Project::PROJECT_PERMITTED_FIELDS.to_set.freeze

  # Given two changesets, produce merged "best" version
  # When confidence is the same, c1 wins.
  def merge_changeset(c1, c2)
    result = c1.dup
    c2.each do |field, data|
      if !result.key?(field) ||
         (data[:confidence] > result[field][:confidence])
        result[field] = data
      end
    end
    result
  end

  # Should we should update a project's value for 'key'?
  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
  def update_value?(project, key, changeset_data)
    if changeset_data.blank? || !changeset_data.member?(key)
      false
    elsif !project.attribute_present?(key) || project[key].blank?
      true
    elsif project[key] == '?'
      true
    else
      changeset_data[:confidence].present? &&
        changeset_data[:confidence] >= CONFIDENCE_OVERRIDE
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

  # Return the best estimates for fields, given project & current proposal.
  def compute_current(fields, project, current_proposal)
    result = {}
    fields.each do |f|
      if update_value?(project, f, current_proposal)
        result[f] = current_proposal[f][:value]
      elsif project.attribute_present?(f)
        result[f] = project[f]
      end
    end
    result
  end

  def log_detective_failure(source, e, detective, proposal, data)
    Rails.logger.error(
      "In method #{source}, exception #{e} on #{detective.class.name}, " \
      "current_proposal= #{proposal}, current_data= #{data}"
    )
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

  # Analyze project and reply with a changeset in the form
  # { fieldname1: { value: value, confidence: 1..5, explanation: text}, ...}
  # Do this by determining the right order and way to invoke "detectives"
  # for this project, invoke them, and process their results.
  def propose_changes
    current_proposal = {} # Current best changeset.
    # TODO: Create topographical sort and Real loop over detectives.
    ALL_DETECTIVES.each do |detective_class|
      detective = detective_class.new
      detective.octokit_client_factory = @client_factory
      current_proposal = propose_one_change(detective, current_proposal)
    end
    current_proposal
  end

  # Given project data, return it with the proposed changeset applied.
  # Note: This should probably be class-level
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def apply_changes(project, changes)
    changes.each do |key, data|
      next unless ALLOWED_FIELDS.include?(key)
      next unless update_value?(project, key, changes)
      # Store change:
      project[key] = data[:value]
      # Now add the explanation, if we can.
      next unless key.to_s.end_with?('_status') && data.key?(:explanation)
      justification_key =
        (key.to_s.chomp('_status') + '_justification').to_sym
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

  # Given form data about a project, return an improved version.
  def autofill
    my_proposed_changes = propose_changes
    apply_changes(@evidence.project, my_proposed_changes)
  end
end
