# Examine repository files at the top level and in documentation directories.

class FileCheckDetective < Detective
  INPUTS = [:repo_files]
  OUTPUTS = [:contribution_status]

  # Minimum file sizes before they should count.
  # Empty files, in particular, clearly do NOT have enough content.
  CONTRIBUTION_MIN_SIZE = 100
  CHANGELOG_MIN_SIZE = 40

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

    contribution = files_named(
      /\A(contributing|contribute)(|\.md|\.txt)?\Z/i, CONTRIBUTION_MIN_SIZE)
    if contribution.empty?
      results[:contribution_status] =
        { value: 'Unmet', confidence: 1,
          explanation: 'No contribution file found.' }
    else
      results[:contribution_status] =
        { value: 'Met', confidence: 5,
          explanation: 'Non-trivial contribution file in repository: ' \
            "<#{contribution.first['html_url']}>." }
    end

    changelog = files_named(
      /\A(changelog)(|\.md|\.txt)?\Z/i, CHANGELOG_MIN_SIZE)
    if changelog.empty?
      results[:changelog_status] =
        { value: 'Unmet', confidence: 1,
          explanation: 'No changelog file found.' }
    else
      results[:changelog_status] =
        { value: 'Met', confidence: 5,
          explanation: 'Non-trivial changelog file in repository: ' \
            "<#{changelog.first['html_url']}>." }
    end

    results
  end
end
