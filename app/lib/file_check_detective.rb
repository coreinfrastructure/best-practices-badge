# Quickly check files for easy guesses.
# and set an appropriate :repo_files accessor.
# Currently we only handle GitHub; extend this to support other ways.

class FileCheckDetective < Detective
  # Individual detectives must identify their inputs, outputs
  INPUTS = [:repo_files]
  OUTPUTS = [:contribution_status]

  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    # top_level = repo_files.get('/')
    # Top_level is iterable, contains a hash with name, size, type (file?).
    # warn "DEBUG: Top level .first = #{top_level.first}"

    # { oss_license_osi_status:
    #     { value: 'Met', confidence: 5,
    #       explanation: "The #{license} license is approved by the " \
    #                    'Open Source Initiative (OSI).' },
    {}
  end
end
