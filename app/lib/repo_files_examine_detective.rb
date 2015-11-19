# Examine repository files at the top level and in documentation directories.
# Note that a key precondition is determining how to open repo files.

class RepoFilesExamineDetective < Detective
  INPUTS = [:repo_files]
  OUTPUTS = [:contribution_status]

  # Minimum file sizes before they count.
  # Empty files, in particular, clearly do NOT have enough content.
  CONTRIBUTION_MIN_SIZE = 100
  CHANGELOG_MIN_SIZE = 40

  # Given an enumeration of fso info hashes, return the fso info for files
  # that match the regex name pattern and are at least minimum_size in length.
  def files_named(name_pattern, minimum_size)
    @top_level.select do |fso|
      fso['type'] == 'file' && fso['name'].match(name_pattern) &&
        fso['size'] >= minimum_size
    end
  end

  def unmet_result(result_description)
    { value: 'Unmet', confidence: 1,
      explanation: "No #{result_description} file found." }
  end

  def met_result(result_description, html_url)
    { value: 'Met', confidence: 3,
      explanation:
        "Non-trivial #{result_description} file in repository: " \
        "<#{html_url}>." }
  end

  def determine_results(status, name_pattern, minimum_size, result_description)
    found_files = files_named(name_pattern, minimum_size)
    @results[status] =
      if found_files.empty?
        unmet_result result_description
      else
        met_result result_description, found_files.first['html_url']
      end
  end

  # rubocop:disable Metrics/MethodLength
  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    @results = {}

    # Top_level is iterable, contains a hash with name, size, type (file|dir).
    @top_level = repo_files.get_info('/')

    # TODO: Look in subdirectories.

    determine_results(
      :contribution_status,
      /\A(contributing|contribute)(|\.md|\.txt)?\Z/i,
      CONTRIBUTION_MIN_SIZE, 'contribution')

    determine_results(
      :changelog_status,
      /\A(changelog)(|\.md|\.txt)?\Z/i,
      CHANGELOG_MIN_SIZE, 'changelog')

    @results
  end
end
