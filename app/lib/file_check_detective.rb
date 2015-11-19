# Examine repository files at the top level and in documentation directories.

class FileCheckDetective < Detective
  INPUTS = [:repo_files]
  OUTPUTS = [:contribution_status]

  CONTRIBUTION_SIZE = 100

  # Return with array of directory names matching name pattern.
  # def dirs(contents, name)
  # end

  # Given an enumeration of fso info hashes, return the fso infos
  # that match the regex name pattern and are at least minimum_size in length.
  def files_named(name, minimum_size)
    @top_level.select do |fso|
      fso['type'] == 'file' && fso['name'].match(name) &&
        fso['size'] >= minimum_size
    end
  end

  # rubocop:disable Metrics/MethodLength
  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    results = {}

    # Top_level is iterable, contains a hash with name, size, type (file|dir).
    @top_level = repo_files.get_info('/')

    # TODO: Look in subdirectories.

    contribution_files = files_named(
      /\A(contributing|contribute)(\.md|\.txt)?\Z/i, CONTRIBUTION_SIZE)

    if contribution_files.empty?
      results[:contribution_status] =
        { value: 'Unmet', confidence: 1,
          explanation: 'No contribution file found.' }
    else
      results[:contribution_status] =
        { value: 'Met', confidence: 5,
          explanation: 'Non-trivial contribution file in repository: ' \
            "<#{contribution_files.first['html_url']}>." }
    end

    results
  end
end
