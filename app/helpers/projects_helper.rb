# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Helper module providing projects view functionality.
# rubocop:disable Metrics/ModuleLength
module ProjectsHelper
  NO_REPOS = [[], []].freeze # No forks and no originals
  EMPTY_ARRAY = [].freeze # Memory optimization for empty header returns

  # Regex for stripping invalid characters from section IDs
  # Only allow lowercase letters, digits, underscore, and hyphen
  SECTION_ID_INVALID_CHARS = /[^a-z0-9_-]/

  # Invoke markdown processor, which is in its own module.
  # @param content [String] The content to render as Markdown
  def markdown(content)
    MarkdownProcessor.render(content)
  end

  # Convert a status integer value to its string representation.
  # @param value [Integer] Status value (0-3)
  # @return [String] String representation ('?', 'Unmet', 'N/A', 'Met')
  # @return [nil] if value is nil or out of range
  #
  # This method converts database status values to their
  # external API string representations for backward compatibility.
  #
  # Handles both pre-migration strings and post-migration integers
  # for graceful deployment during the enum optimization rollout.
  # This defensive approach prevents crashes if any cached/serialized
  # string values exist.
  #
  # Examples:
  #   status_to_string(0) # => '?'
  #   status_to_string(1) # => 'Unmet'
  #   status_to_string(2) # => 'N/A'
  #   status_to_string(3) # => 'Met'
  #   status_to_string('Met') # => 'Met' (pre-migration compatibility)
  #   status_to_string(nil) # => nil
  def status_to_string(value)
    return if value.nil?
    return value if value.is_a?(String) # Pre-migration: already a string

    CriterionStatus::STATUS_VALUES[value]
  end

  # List original then forked Github projects, with headers
  def github_select
    retrieved_repo_data = repo_data # Get external data
    fork_repos, original_repos = fork_and_original(retrieved_repo_data)
    original_header(original_repos) + original_repos +
      fork_header(fork_repos) + fork_repos
  end

  # Handles fork and original functionality.
  # @param retrieved_repo_data - Repository data from GitHub API
  def fork_and_original(retrieved_repo_data)
    if retrieved_repo_data.blank?
      NO_REPOS
    else
      retrieved_repo_data.partition { |repo| repo[1] }
    end
  end

  # @param original_repos [Array] Array of original (non-fork) repositories
  def original_header(original_repos)
    original_repos.blank? ? EMPTY_ARRAY : [[t('.original_repos'), '', 'none']]
  end

  # @param fork_repos [Array] Array of forked repositories
  def fork_header(fork_repos)
    fork_repos.blank? ? EMPTY_ARRAY : [[t('.fork_repos'), '', 'none']]
  end

  # Use the status_chooser to render the given criterion.
  # rubocop:disable Metrics/ParameterLists
  def render_status(
    criterion, f, project, criteria_level, view_only, is_last = false
  )
    render(
      partial: 'status_chooser',
      locals: {
        f: f, project: project, criteria_level: criteria_level,
        view_only: view_only, is_last: is_last,
        criterion: Criteria[criteria_level][criterion.to_sym]
      }
    )
  end

  # Generate HTML for minor heading
  # @param minor [Object] The minor heading text
  # rubocop:enable Metrics/ParameterLists
  def minor_header_html(minor)
    # rubocop:disable Rails/OutputSafety
    # Section ids are section_ followed by lowercased letters, digits, _ for space
    # We strip out everything else.
    # Use string interpolation to avoid intermediate string allocation
    section_id = "section_#{minor.downcase.tr(' ', '_').gsub(SECTION_ID_INVALID_CHARS, '')}"

    safe_join(
      [
        '<li class="list-group-item"><h3 id="'.html_safe,
        section_id,
        '">'.html_safe,
        t(minor, scope: [:headings]),
        '</h3>'.html_safe
      ]
    )
    # rubocop:enable Rails/OutputSafety
  end

  # Render all the status_choosers in the given minor section.
  # This takes a ridiculous number of parameters, because we have to
  # select the correct minor section & then pass the information the
  # status_chooser needs (which also needs a ridiculous number).
  # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
  # rubocop:disable Metrics/ParameterLists
  def render_minor_status(
    criteria_level, major, minor, f, project, view_only, wrapped = true
  )
    minor_criteria = FullCriteriaHash[criteria_level][major][minor].keys
    raise NameError if minor_criteria.empty? # Should always be true

    results = ActionView::OutputBuffer.new
    results << minor_header_html(minor) if wrapped
    minor_criteria.each do |criterion|
      results << render_status(
        criterion, f, project, criteria_level, view_only,
        criterion == minor_criteria.last
      )
    end
    # rubocop:disable Rails/OutputSafety
    results << safe_join(['</li>'.html_safe]) if wrapped
    # rubocop:enable Rails/OutputSafety
    results
  end

  # Return HTML for a sortable header.
  # @param title [String] The title text for the sortable header
  # @param field_name [Object] The database field name for sorting
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize
  def sortable_header(title, field_name)
    new_params = params.merge(sort: field_name)
                       .permit(ProjectsController::ALLOWED_QUERY_PARAMS)
    if params[:sort] == field_name && params[:sort_direction] != 'desc'
      new_params[:sort_direction] = 'desc'
    else
      new_params.delete(:sort_direction)
    end

    # The html_safe assertion here allows the HTML of
    # <a href...> to go through.  This *is* handled for security;
    # params.merge performs the URL encoding as required, and "title" is
    # trusted (it's provided by the code, not by a potential attacker).
    # We use "nofollow" to discourage search engines from following it
    # rubocop:disable Rails/OutputSafety
    "<a href=\"#{url_for(new_params)}\" rel=\"nofollow\">#{title}</a>".html_safe
    # rubocop:enable Rails/OutputSafety
  end

  # Given tiered percentage as integer value, return its string representation
  # Returns nil if given blank value.
  # @param value [Object] The value to process
  # rubocop:disable Metrics/MethodLength
  def tiered_percent_as_string(value)
    return if value.blank?

    partial = value % 100
    if value < 100
      I18n.t 'projects.index.in_progress_next', percent: partial
    elsif value < 200
      I18n.t 'projects.index.passing_next', percent: partial
    elsif value < 300
      I18n.t 'projects.index.silver_next', percent: partial
    elsif value >= 300
      I18n.t 'projects.form_early.level.2'
    end
  end
  # rubocop:enable Metrics/MethodLength

  # We sometimes insert <wbr> after sequences of these characters.
  WORD_BREAK_DIVIDERS = /([,_\-.]+)/

  # This text is considered safe, so we can directly mark it as such.
  # rubocop:disable Rails/OutputSafety
  SAFE_WORD_BREAK = '<wbr>'.html_safe
  # rubocop:enable Rails/OutputSafety

  # Insert wbr (HTML word break) after _ etc. per WORD_BREAK_DIVIDERS.
  # The text is presumed to be unsafe.  We produce a safe (escaped) HTML result.
  # @param text [String] The text content to break down into words
  def word_breakdown(text)
    safe_join(
      text.split(WORD_BREAK_DIVIDERS).each_with_index.map do |fragment, i|
        i.even? ? fragment : h(fragment) + SAFE_WORD_BREAK
      end,
      ''
    )
  end

  # Module method: Computes display form for a baseline ID.
  # This is private and only used during constant initialization.
  # Internal: osps_ac_03_01 (lowercase, underscores)
  # Display: OSPS-AC-03.01 (uppercase, dashes, dot before last segment)
  # Also handles field names:
  # Internal: osps_ac_03_01_status
  # Display: OSPS-AC-03.01_status
  # @param id_str [String] baseline ID or field name in internal form
  # @return [String] baseline ID or field name in display form, or original
  # rubocop:disable Metrics/AbcSize
  def self.compute_baseline_display_name(id_str)
    # Only convert if it looks like a baseline ID (starts with osps_)
    return id_str unless id_str.start_with?('osps_')

    # Split on underscores: osps_ac_03_01 -> [osps, ac, 03, 01]
    # or osps_ac_03_01_status -> [osps, ac, 03, 01, status]
    parts = id_str.split('_')

    if parts.size == 4
      # Criterion ID: OSPS-AC-03.01
      "#{parts.first.upcase}-#{parts[1].upcase}-#{parts[2]}.#{parts[3]}"
    elsif parts.size == 5 && %w[status justification].include?(parts[4])
      # Field name: OSPS-AC-03.01_status
      "#{parts.first.upcase}-#{parts[1].upcase}-#{parts[2]}.#{parts[3]}_#{parts[4]}"
    else
      id_str # Return original if not recognized format
    end
  end
  # rubocop:enable Metrics/AbcSize
  private_class_method :compute_baseline_display_name

  # Module method: Computes internal form for a baseline ID in display form.
  # This is private and only used during constant initialization.
  # Display: OSPS-AC-03.01 (uppercase, dashes, dot)
  # Internal: osps_ac_03_01 (lowercase, underscores)
  # @param id_str [String] baseline ID in display form
  # @return [String] baseline ID in internal form, or original if not baseline
  def self.compute_baseline_internal_name(id_str)
    # Only convert if it looks like a baseline ID (starts with OSPS-)
    return id_str unless id_str.match?(/^OSPS-/i)

    # Convert to lowercase and replace dashes/dots with underscores
    # OSPS-AC-03.01 -> osps_ac_03_01
    id_str.downcase.tr('-.', '__')
  end
  private_class_method :compute_baseline_internal_name

  # Precomputed mapping: Project field names from internal to display form.
  # Computed once at load time, eliminating repeated transformations and GC.
  # Only includes fields that need transformation (baseline fields).
  BASELINE_FIELD_DISPLAY_NAME_MAP =
    Project.column_names.each_with_object({}) do |name, hash|
      transformed = compute_baseline_display_name(name)
      hash[name] = transformed if transformed != name
    end
  BASELINE_FIELD_DISPLAY_NAME_MAP.freeze

  # We currently don't use this mapping of external->internal names,
  # we instead use internal names and occasionally translate them to
  # external names for display. However, it's conceivable that we might
  # want to do that (e.g., accept JSON files with external display keys),
  # so here's how to compute that.
  # Precomputed mapping: Baseline display names to internal field names.
  # Computed once at load time, eliminating repeated transformations and GC.
  # BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP =
  #   BASELINE_FIELD_DISPLAY_NAME_MAP.each_with_object({}) do |(internal, display), hash|
  #     hash[display] = internal
  #   end
  # BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.freeze

  # Instance method: Converts baseline ID from internal form to display form.
  # Uses precomputed map for database fields (O(1), no allocations).
  # Falls back to computation for non-field IDs (e.g., criterion IDs).
  # @param id [String, Symbol] baseline ID or field name in internal form
  # @return [String] baseline ID or field name in display form, or original
  def baseline_id_to_display(id)
    id_str = id.to_s
    # Fast path: Use precomputed map for database fields
    return BASELINE_FIELD_DISPLAY_NAME_MAP[id_str] if
      BASELINE_FIELD_DISPLAY_NAME_MAP.key?(id_str)

    # Fallback: Compute for criterion IDs not in database
    return id_str unless id_str.start_with?('osps_')

    parts = id_str.split('_')
    if parts.size == 4
      "#{parts.first.upcase}-#{parts[1].upcase}-#{parts[2]}.#{parts[3]}"
    else
      id_str
    end
  end

  # We currently don't use this mapping of external->internal names, but
  # here's a way to do that.
  # Instance method: Converts baseline ID from display form to internal form.
  # Uses precomputed map for database fields (O(1), no allocations).
  # Falls back to computation for non-field IDs (e.g., criterion IDs).
  # @param id [String] baseline ID in display form
  # @return [String] baseline ID in internal form, or original if not baseline
  # def baseline_id_to_internal(id)
  #   id_str = id.to_s
  #   # Fast path: Use precomputed map for database fields
  #   return BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP[id_str] if
  #     BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.key?(id_str)
  #   # Fallback: Compute for criterion IDs not in database
  #   return id_str unless id_str.match?(/^OSPS-/i)
  #   id_str.downcase.tr('-.', '__')
  # end

  # Generate a radio button for a status field, handling integer↔string conversion.
  # Status values are stored as integers in the database but displayed as strings
  # in forms. This helper reads the integer value, converts it to a string for
  # comparison with the radio button value, and generates the appropriate HTML.
  #
  # @param form [ActionView::Helpers::FormBuilder] The form builder (f)
  # @param project [Project] The project instance
  # @param status_field [Symbol] The status field name (e.g., :description_good_status)
  # @param string_value [String] The radio button value ('Met', 'Unmet', 'N/A', '?')
  # @param ** [Hash] Additional keyword arguments passed to radio_button (label:, disabled:, etc.)
  # @return [String] HTML for the radio button
  def status_radio_button(form, project, status_field, string_value, **)
    # Read the raw integer value from the database and convert to string
    current_string = status_to_string(project[status_field])

    # Determine if this radio button should be checked
    checked = (current_string == string_value)

    # Generate the radio button using bootstrap_form's radio_button helper
    # We pass the string value so the form submits strings (which the controller converts)
    form.radio_button(status_field, string_value, checked: checked, **)
  end
end
# rubocop:enable Metrics/ModuleLength
