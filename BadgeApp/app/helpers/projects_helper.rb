module ProjectsHelper
  def github_select
    fork_repos, original_repos = fork_and_original
    original_header(original_repos) + text_and_value(original_repos) +
      fork_header(fork_repos) + text_and_value(fork_repos)
  end

  def fork_and_original
    github = Github.new oauth_token: session[:user_token]
    repo_data = github.repos.list.map do |repo|
      { full_name: repo.full_name, html_url: repo.html_url, fork: repo.fork }
    end
    repo_data.partition { |repo| repo[:fork] }
  end

  def original_header(original_repos)
    original_repos.blank? ? [] : [['=> Original Github Repos', '']]
  end

  def fork_header(fork_repos)
    fork_repos.blank? ? [] : [['=> Forked Github Repos', '']]
  end

  def text_and_value(repos)
    repos.map { |repo| [repo[:full_name], repo[:html_url]] }
  end
end
