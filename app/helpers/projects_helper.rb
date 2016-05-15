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

  def markdown(content)
    return '' if content.nil?
    MARKDOWN_PROCESSOR.render(content).html_safe
  end

  # Use the status_chooser to render the given criterion.
  def render_status(criterion, f, project, is_disabled, is_last = false)
    render(
      partial: 'status_chooser',
      locals: {
        f: f, project: project, is_disabled: is_disabled,
        is_last: is_last, criterion: Criteria[criterion]
      }
    )
  end

  def repo_url_disabled?(project)
    true unless current_user.admin? || !project.repo_url?
  end
end
