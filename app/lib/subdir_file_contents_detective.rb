# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Examine repository files at the top level and in key subdirectories
# (those conventionally used for source and documentation).
# Note that a key precondition is determining how to open repo files.

class SubdirFileContentsDetective < Detective
  INPUTS = [:repo_files].freeze
  OUTPUTS = [:documentation_basics_status].freeze
  DOCS_BASICS = {
    folder: /\Adoc(s|umentation)?\Z/i,
    file: /(\.md|\.markdown|\.txt|\.html)?\Z/i,
    contents: [/install(ation)?/i, /us(e|ing)/i, /secur(e|ity)/i].freeze
  }.freeze

  def unmet_result(result_description)
    {
      value: 'Unmet', confidence: 1,
      explanation: "// No #{result_description} file(s) found."
    }
  end

  def unmet_result_folder(result_description)
    {
      value: 'Unmet', confidence: 3,
      explanation: "// No appropriate folder found for #{result_description}."
    }
  end

  def met_result(result_description)
    {
      value: 'Met', confidence: 3,
      explanation:
        "Some #{result_description} file contents found."
    }
  end

  def match_fso?(fso, type, name_pattern)
    fso['type'] == type && fso['name'].match(name_pattern)
  end

  def folder_named(name_pattern)
    @top_level.select do |fso|
      return fso['name'] if match_fso?(fso, 'dir', name_pattern)
    end
    nil
  end

  def match_file_content(repo_files, folder, patterns, description)
    files = repo_files.get_info(folder)
    files = files.select { |f| match_fso?(f, 'file', patterns[:file]) }
    files.select do |fso|
      patterns[:contents].each do |pattern|
        file_entry = repo_files.get_info(fso['path'])
        content = Base64.decode64(file_entry['content'])
        return met_result description if content.match?(pattern)
      end
    end
    unmet_result description
  end

  def determine_content_results(repo_files, status, patterns, description)
    folder = folder_named(patterns[:folder])
    @results[status] =
      if folder.nil?
        unmet_result_folder description
      else
        match_file_content(repo_files, folder, patterns, description)
      end
  end

  def analyze(_evidence, current)
    repo_files = current[:repo_files]
    return {} if repo_files.blank?

    @results = {}

    # Top_level is iterable, contains a hash with name, size, type (file|dir).
    @top_level = repo_files.get_info('/')
    determine_content_results(
      repo_files, :documentation_basics_status, DOCS_BASICS,
      'documentation basics'
    )
    @results
  end
end
