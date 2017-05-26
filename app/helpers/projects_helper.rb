# frozen_string_literal: true

module ProjectsHelper
  MARKDOWN_RENDERER = Redcarpet::Render::HTML.new(
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true
  )
  MARKDOWN_PROCESSOR = Redcarpet::Markdown.new(
    MARKDOWN_RENDERER,
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true
  )

  def github_select
    # List original then forked Github projects, with headers
    fork_repos, original_repos = fork_and_original
    original_header(original_repos) + original_repos +
      fork_header(fork_repos) + fork_repos
  end

  def fork_and_original
    repo_data.partition { |repo| repo[1] } # partition on fork
  end

  def original_header(original_repos)
    original_repos.blank? ? [] : [['=> Original Github Repos', '', 'none']]
  end

  def fork_header(fork_repos)
    fork_repos.blank? ? [] : [['=> Forked Github Repos', '', 'none']]
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
    safe_join(
      [
        '<li class="list-group-item"><h3>'.html_safe,
        t(minor, scope: [:headings]),
        '</h3>'.html_safe
      ]
    )
  end

  # Render all the status_choosers in the given minor section.
  # This takes a rediculous number of parameters, because we have to
  # select the correct minor section & then pass the information the
  # status_chooser needs (which also needs a rediculous number).
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
    results << safe_join(['</li>'.html_safe]) if wrapped
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
    # rubocop:disable Rails/OutputSafety
    "<a href=\"#{url_for(new_params)}\">#{title}</a>".html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
