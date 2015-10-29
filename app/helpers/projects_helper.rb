module ProjectsHelper
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
end
