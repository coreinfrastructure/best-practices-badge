# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Helper module providing projects view functionality.
# rubocop:disable Metrics/ModuleLength
module ProjectsHelper
  # Markdown renderer configuration
  MARKDOWN_RENDERER_OPTIONS = {
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true,
    link_attributes: { rel: 'nofollow ugc' }
  }.freeze
  MARKDOWN_PROCESSOR_OPTIONS = {
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true
  }.freeze

  # The following pattern is designed to *only* match
  # a line that we KNOW cannot require markdown processing.
  # MODIFY THIS PATTERN TO TEST!

  # This pattern matches text that we KNOW does not require markdown processing.
  # We do this check as an optimization to skip calling the markdown
  # processor in most cases when it's clearly unnecessary.
  # In particular, note that we have to handle period and colon specially,
  # because www.foo.com and http://foo.com *do* need to be processed
  # as markdown.

  # In our measures this matches 83.87% of the justification text in our system.
  # That's a pretty good optimization that is not *too* hard to read and verify.
  # It's *okay* to pass something to the markdown processor, we just try
  # to ensure that most such requests are needed.

  # IMPORTANT CONSTRAINTS:
  # - Must NOT match numbered lists (e.g., "1. Item")
  #   markdown formats them as <ol><li>.
  # - Must NOT match un-numbered lists (e.g., "* Item")
  # - Must NOT match headings ("# foo")
  # - Must NOT match URLs (e.g., "https://github.com/foo") because
  #   markdown auto-links them (autolink: true option).
  # - Must NOT match implied domain names like www.foo.com or email addresses.
  #   (autolink: true option).
  #   We avoid matching possible domain names and URLs and email addresses
  #   by only allowing a period or colon if it's followed by a space, and
  #   only allowing "/" if it's followed by an alphanumeric or a "slash space".
  #   We also don't accept "@".
  # - Must NOT require HTML escaping, e.g., no "<" or ">".
  #   We can allow "&" followed by a space, as modern HTML knows that can't
  #   be an entity. We can allow single-quotes and double-quotes since
  #   this is not in an attribute and we aren't implementing smarty quotes.

  MARKDOWN_UNNECESSARY = %r{\A
    (?!(\d+\.|\-|\*|\+|\#+)\s) # numbered lists, un-numbered lists, headings
    (?!\-\-\-) # Horizontal lines
    ([A-Za-z0-9\040\,\;\'\"\!\(\)\-\?\%\+]|
     \.\040|\:\040|\&\040|/(/\040|[A-Za-z0-9]))+
    \.? # Optional final period
    \z}x

  MARKDOWN_PREFIX = '<p>'
  MARKDOWN_SUFFIX = "</p>\n"

  NO_REPOS = [[], []].freeze # No forks and no originals
  EMPTY_ARRAY = [].freeze # Memory optimization for empty header returns

  # Regex for stripping invalid characters from section IDs
  # Only allow lowercase letters, digits, underscore, and hyphen
  SECTION_ID_INVALID_CHARS = /[^a-z0-9_-]/

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

  # REDCARPET THREAD-SAFETY WORKAROUND
  #
  # Redcarpet (v3.6.1) claims to be thread-safe but has subtle bugs in its C
  # extension. Its C code has global state (work buffers in md->work_bufs[])
  # that gets corrupted when multiple threads call render() simultaneously,
  # even when each thread uses a separate Redcarpet::Markdown instance.
  # This causes segmentation faults with the error:
  #   Assertion failed: (md->work_bufs[BUFFER_BLOCK].size == 0),
  #   function sd_markdown_render, file markdown.c, line 2544
  #
  # We experienced crashes with 56 concurrent threads in CI/CD. GitLab hit the
  # same issue and documented their workaround in MR #14604:
  # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14604
  #
  # Redcarpet issue tracker confirms the problem:
  # - https://github.com/vmg/redcarpet/issues/184 (no built-in thread safety)
  # - https://github.com/vmg/redcarpet/issues/569 (segfaults with :quote)
  #
  # Our workaround uses BOTH thread-local storage AND a mutex (defense in depth):
  # - Thread-local storage: Each thread gets its own instance (avoids most issues)
  # - Mutex: Serializes all render() calls to protect Redcarpet's global C state
  #
  # Both protections are necessary because Redcarpet has bugs at two levels:
  # 1. Instance level (need separate instances per thread)
  # 2. Global state level (need serialized access even with separate instances)
  #
  # The mutex is initialized in config/initializers/markdown.rb as a global
  # variable to survive Rails class reloading in development/test environments.

  # Render markdown content to HTML.
  #
  # This method works around Redcarpet's thread-safety bugs by using both
  # thread-local storage and mutex serialization. See $markdown_mutex comments
  # above for details on why both protections are necessary.
  #
  # For simple text with no markdown syntax, we bypass Redcarpet entirely for
  # performance. The markdown renderer is configured with filter_html:true for
  # security, but rubocop can't detect this, hence the OutputSafety disable.
  #
  # @param content [String] The content to render as Markdown
  # @return [ActiveSupport::SafeBuffer] HTML-safe rendered output
  # We have to disable Rails/OutputSafety because Rubocop can't do the
  # advanced reasoning needed to determine this isn't vulnerable to CSS.
  # The MARKDOWN_UNNECESSARY pattern doesn't match "<" etc.
  # The markdown processor is configured to output safe strings.
  # rubocop:disable Rails/OutputSafety, Metrics/MethodLength
  def markdown(content)
    # Return empty string if content is blank.
    # Ruby always returns the exact same empty string object (per object_id)
    # if it's asked to return a literal empty string from a source file
    # with `frozen_string_literal: true`.
    # So this next line *never* allocates a new object, even though it
    # *appears* that it might.
    return '' if content.blank?

    # Strip away leading/trailing whitespace. This makes it easier for
    # us to detect numbered lists, etc. Leading and trailing space
    # doesn't really make any sense in this context. The .to_s is
    # defensive; normally it won't do anything other
    # than return what was passed.
    content = content.to_s.strip

    # Skip markdown processing for simple text with no markdown syntax
    # and no way to generate dangerous code (e.g., no < or >).
    # At one time we called html_escape, but that is completely unnecessary
    # because MARKDOWN_UNNECESSARY won't let those sequences in, and
    # removing the unnecessary call helps us avoid unnecessary work and
    # unnecessary string allocation. We concatenate all at once to
    # avoid creating unnecessary temporary strings as intermediaries.
    # We declare the result as html_safe so that views can more efficiently
    # use the result.
    if content.match?(MARKDOWN_UNNECESSARY)
      return "#{MARKDOWN_PREFIX}#{content}#{MARKDOWN_SUFFIX}".html_safe
    end

    # WORKAROUND: Protect against Redcarpet's thread-safety bugs.
    # The mutex prevents concurrent access to Redcarpet's global C state,
    # while thread-local storage ensures each thread has its own instance.
    # Both protections are necessary - see $markdown_mutex comments above.
    $markdown_mutex.synchronize do # rubocop:disable Style/GlobalVars
      # Get or create this thread's Redcarpet processor instance
      processor = Thread.current[:markdown_processor]
      # Create new instance if needed. This can happen on first use or
      # if Rails class reloading invalidates the cached instance.
      unless processor.is_a?(Redcarpet::Markdown)
        renderer = Redcarpet::Render::HTML.new(MARKDOWN_RENDERER_OPTIONS)
        processor = Redcarpet::Markdown.new(renderer, MARKDOWN_PROCESSOR_OPTIONS)
        Thread.current[:markdown_processor] = processor
      end

      processor.render(content).html_safe
    end
  end
  # rubocop:enable Rails/OutputSafety, Metrics/MethodLength

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
