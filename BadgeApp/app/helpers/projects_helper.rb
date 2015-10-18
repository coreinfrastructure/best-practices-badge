module ProjectsHelper
  def github_select
    github = Github.new oauth_token: session[:user_token]
    repo_data = github.repos.list.map do |repo|
      { full_name: repo.full_name, fork: repo.fork, html_url: repo.html_url }
    end
    fork_repos, original_repos = repo_data.partition { |repo| repo[:fork] }
    # f.collection_select :repo_url, repo_data, :html_url, :full_name, { include_blank: true }
    ordered_repos = []
    ordered_repos.push original_header unless original_repos.blank?
    ordered_repos.push text_and_value(original_repos)
    ordered_repos.push fork_header unless fork_repos.blank?
    ordered_repos.push text_and_value(fork_repos)
    # byebug
    ordered_repos
    # byebug
  end

  def original_header
    ['Original Github Repos', '']
  end

  def fork_header
    ['Forked Github Repos', '']
  end

  def text_and_value(repos)
    repos.map { |repo| [repo[:full_name], repo[:html_url]] }
  end
end
