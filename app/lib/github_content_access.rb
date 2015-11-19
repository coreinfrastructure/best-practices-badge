require 'json'

# Accessor to GitHub so we can read (file) content info from GitHub.
# Use this indirect class so that we can later plug in other accessors to
# read data from other locations.
class GithubContentAccess
  def initialize(fullname)
    @fullname = fullname
  end

  # The GitHub contents API is defined here:
  # https://developer.github.com/v3/repos/contents/
  # Basically: https://api.github.com/repos/:owner/:repo/contents/:path
  # E.G.: https://api.github.com/repos/
  # linuxfoundation/cii-best-practices-badge/contents
  # We use the Octokit gem to simplify access.

  # Given a filename, reply with information about it.
  # - For files (type='file') this is a hash of data
  #   Fields include: name, path, size, html_url.
  # - For directories (type='dir') this is an iterable set of hashes;
  #   each hash represents a filesystem object (see above)
  def get_info(filename)
    JSON.parse(Octokit.contents(@fullname, path: filename))
  end
end
