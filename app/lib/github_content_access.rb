require 'json'

# Accessor to GitHub so we can read (file) content from GitHub.
# Use this indirect class so that we can later plug in other accessors to
# read data from other locations.
class GithubContentAccess
  def initialize(fullname)
    @fullname = fullname
  end

  # Given a filename, reply with its contents.  For directories this
  # is an iterable set of hashes; each hash represents a filesystem object,
  # and the fields include 'name' and 'size'.
  def get(filename)
    JSON.parse(Octokit.contents(@fullname, path: filename))
  end
end
