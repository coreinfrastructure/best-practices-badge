require 'json'

# If it's a GitHub repo, grab easily-acquired data from GitHub API and
# use it to determine key values for project.

class GithubBasicDetective
  # Individual detectives must identify their inputs, outputs
  INPUTS = [:repo_url]
  OUTPUTS = [:name, :license]

  # Individual detectives must implement "analyze"
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def analyze(evidence)
    return {} if evidence.repo_url.nil?

    results = {}
    # Has form https://github.com/:user/:name?
    # e.g.: https://github.com/linuxfoundation/cii-best-practices-badge
    # Note: this limits what's accepted, otherwise we'd have to worry
    # about URL escaping.
    evidence.repo_url.match(
      %r{\Ahttps://github.com/([A-Za-z0-9_-]+)/([A-Za-z0-9_-]+)/?\Z}) do |m|
      # We have a github repo.  Get basic evidence using GET, e.g.:
      # https://api.github.com/repos/linuxfoundation/cii-best-practices-badge
      fullname = m[1] + '/' + m[2]
      basic_repo_data_raw = evidence.get(
        'https://api.github.com/repos/' + fullname)
      if !basic_repo_data_raw.blank?
        basic_repo_data = JSON.parse(basic_repo_data_raw)
        if basic_repo_data[:description]
          results[:name] = {
            value: basic_repo_data[:description],
            confidence: 3, explanation: 'GitHub description' }
        end
      end

      # We'll ask GitHub what the license is.  This is a "preview"
      # API subject to change without notice, and doesn't do much analysis,
      # but it's a quick win to figure it out.
      license_data_raw = evidence.get(
        'https://api.github.com/repos/' + fullname + '/license')
      license_data = JSON.parse(license_data_raw)
      if license_data[:license] && license_data[:license][:key]
        # GitHub doesn't reply with the expected upper/lower case for SPDX;
        # 'upcase' handles common cases.  See:
        # https://github.com/benbalter/licensee/issues/72
        results[:license] = {
          value: basic_repo_data[:license][:key].upcase,
          confidence: 3, explanation: 'GitHub API license analysis' }
      end
    end
    results
  end
end
