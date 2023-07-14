# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ModuleLength
module ProjectsHelper
  MARKDOWN_RENDERER = Redcarpet::Render::HTML.new(
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true,
    link_attributes: { rel: 'nofollow ugc' }
  )
  MARKDOWN_PROCESSOR = Redcarpet::Markdown.new(
    MARKDOWN_RENDERER,
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true
  )
  NO_REPOS = [[], []].freeze # No forks and no originals

  # List original then forked Github projects, with headers
  def github_select
    retrieved_repo_data = repo_data # Get external data
    fork_repos, original_repos = fork_and_original(retrieved_repo_data)
    original_header(original_repos) + original_repos +
      fork_header(fork_repos) + fork_repos
  end

  def fork_and_original(retrieved_repo_data)
    if retrieved_repo_data.blank?
      NO_REPOS
    else
      retrieved_repo_data.partition { |repo| repo[1] }
    end
  end

  def original_header(original_repos)
    original_repos.blank? ? [] : [[t('.original_repos'), '', 'none']]
  end

  def fork_header(fork_repos)
    fork_repos.blank? ? [] : [[t('.fork_repos'), '', 'none']]
  end

  # Render markdown.  This is safe because the markdown renderer in use is
  # configured with filter_html:true, but rubocop has no way to know that.
  # rubocop:disable Rails/OutputSafety
  def markdown(content)
    return '' if content.nil?

    MARKDOWN_PROCESSOR.render(content).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  # Use the status_chooser to render the given criterion.
  # rubocop:disable Metrics/ParameterLists
  def render_status(
    criterion, f, project, criteria_level, is_disabled, is_last = false
  )
    render(
      partial: 'status_chooser',
      locals: {
        f: f, project: project, criteria_level: criteria_level,
        is_disabled: is_disabled, is_last: is_last,
        criterion: Criteria[criteria_level][criterion.to_sym]
      }
    )
  end
  # rubocop:enable Metrics/ParameterLists

  # Generate HTML for minor heading
  def minor_header_html(minor)
    # rubocop:disable Rails/OutputSafety
    safe_join(
      [
        '<li class="list-group-item"><h3>'.html_safe,
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
    criteria_level, major, minor, f, project, is_disabled, wrapped = true
  )
    minor_criteria = FullCriteriaHash[criteria_level][major][minor].keys
    raise NameError if minor_criteria.empty? # Should always be true

    results = ActionView::OutputBuffer.new
    results << minor_header_html(minor) if wrapped
    minor_criteria.each do |criterion|
      results << render_status(
        criterion, f, project, criteria_level, is_disabled,
        criterion == minor_criteria.last
      )
    end
    # rubocop:disable Rails/OutputSafety
    results << safe_join(['</li>'.html_safe]) if wrapped
    # rubocop:enable Rails/OutputSafety
    results
  end
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

  # Return HTML for a sortable header.
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
  WORD_BREAK_DIVIDERS = /([,_\-.]+)/.freeze

  # rubocop:disable Rails/OutputSafety
  # This text is considered safe, so we can directly mark it as such.
  SAFE_WORD_BREAK = '<wbr>'.html_safe
  # rubocop:enable Rails/OutputSafety

  # Insert wbr (HTML word break) after _ etc. per WORD_BREAK_DIVIDERS.
  # The text is presumed to be unsafe.  We produce a safe (escaped) HTML result.
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
