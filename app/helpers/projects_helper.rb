module ProjectsHelper
  def github_select
    # List original then forked Github projects, with headers
    fork_repos, original_repos = fork_and_original
    original_header(original_repos) + original_repos +
      fork_header(fork_repos) + fork_repos
  end

  def fork_and_original
    github = Github.new oauth_token: session[:user_token], auto_pagination: true
    repo_data = github.repos.list.map do |repo|
      [repo.full_name, repo.fork, repo.html_url]
    end
    repo_data.partition { |repo| repo[1] } # partition on fork
  end

  def original_header(original_repos)
    original_repos.blank? ? [] : [['=> Original Github Repos', '', 'none']]
  end

  def fork_header(fork_repos)
    fork_repos.blank? ? [] : [['=> Forked Github Repos', '', 'none']]
  end
end
