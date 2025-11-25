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
  NO_REPOS = [[], []].freeze # No forks and no originals

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
    original_repos.blank? ? [] : [[t('.original_repos'), '', 'none']]
  end

  # @param fork_repos [Array] Array of forked repositories
  def fork_header(fork_repos)
    fork_repos.blank? ? [] : [[t('.fork_repos'), '', 'none']]
  end

  # Render markdown.  This is safe because the markdown renderer in use is
  # configured with filter_html:true, but rubocop has no way to know that.
  # Uses thread-local storage to reuse processor instances within a thread
  # while ensuring thread safety, as Redcarpet's C code is not thread-safe
  # with shared instances across threads.
  # @param content [String] The content to render as Markdown
  # rubocop:disable Rails/OutputSafety
  def markdown(content)
    return '' if content.blank?

    # Get or create thread-local markdown processor
    processor = Thread.current[:markdown_processor]
    if processor.nil?
      renderer = Redcarpet::Render::HTML.new(MARKDOWN_RENDERER_OPTIONS)
      processor = Redcarpet::Markdown.new(renderer, MARKDOWN_PROCESSOR_OPTIONS)
      Thread.current[:markdown_processor] = processor
    end

    processor.render(content).html_safe
  end
  # rubocop:enable Rails/OutputSafety

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
    section_id = 'section_' + minor.downcase.tr(' ', '_').gsub(/[^a-z0-9_-]/, '')

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
end
# rubocop:enable Metrics/ModuleLength
