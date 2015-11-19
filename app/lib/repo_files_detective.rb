# Determine how to open the development files in the repository,
# and set an appropriate :repo_files accessor.
# Currently we only handle GitHub; extend this to support other ways.

class RepoFilesDetective < Detective
  # Individual detectives must identify their inputs, outputs
  INPUTS = [:repo_url]
  OUTPUTS = [:repo_files] # Ask :repo_files.get("FILENAME") for files.

  GITHUB_REPO = %r{https?://github.com/([^/]*)/([^/]*)(.git)?}
  def analyze(_evidence, current)
    repo_url = current[:repo_url]
    return {} if repo_url.blank?

    github_match = repo_url.match(GITHUB_REPO)
    if github_match
      fullname = "#{github_match[1]}/#{github_match[2]}"
      { repo_files:
        { value: GithubContentAccess.new(fullname), confidence: 5 } }
    else
      {} # We currently don't handle other cases.
    end
  end
end
