# frozen_string_literal: true
# Examine repository files at the top level and in key subdirectories
# (those conventionally used for source and documentation).
# Note that a key precondition is determining how to open repo files.

# frozen_string_literal: true

class SubdirFileContentsDetective < Detective
  INPUTS = [:repo_files].freeze
  OUTPUTS = %i(
    contribution_status license_location_status release_notes_status
    build_status build_common_tools_status
  ).freeze
  FOLDER_PATTERN = /\Adoc(s|umentation)\Z/i
  FILE_PATTERN = /(\.md|\.markdown|\.txt|\.html)?\Z/i

  def files_in_folder_named(_folder_files, _name_pattern)
    false # TODO: add working code here
  end

  def folder_named(name_pattern)
    @top_level.select do |fso|
      if fso['type'] == 'dir' && fso['name'].match(name_pattern)
        return fso['name']
      end
    end
    nil
  end

  def determine_content_results(
          repo_files, status, required_contents, result_description
  )
    docs = folder_named(FOLDER_PATTERN)
    if docs.nil?
      @results[status] = unmet_result result_description
    else
      find_matching_content_in_files(
        repo_files, required_contents, result_description
      )
    end
  end

  def find_matching_content_in_files(
          repo_files, required_contents, _result_description
  )
    found_files = files_in_folder_named(repo_files.get(docs), FILE_PATTERN)
    required_contents.each do |pattern|
      found_files # TODO: see below
      pattern # TODO: code to look for pattern in found_files
    end
  end

  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    @results = {}

    # Top_level is iterable, contains a hash with name, size, type (file|dir).
    @top_level = repo_files.get_info('/')

    determine_content_results(
      repo_files, :documentation_basics_status,
      [/install(ation)?/i, /us(e|ing)/i, /secur(e|ity)/i],
      'documentation basics'
    )
  end
end
