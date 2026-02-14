# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class SubdirFileContentsDetectiveTest < ActiveSupport::TestCase
  def setup
    super
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'
    @evidence = Evidence.new({})
    @repo_url = "https://github.com/#{@full_name}"
    @full_name2 = 'david-a-wheeler/test-badge-project'
    @human_name2 = 'A test for transferring projects'
    @evidence2 = Evidence.new({})
    @repo_url = "https://github.com/#{@full_name2}"
  end

  test 'Subdir File Contents Detective Test' do
    VCR.use_cassette('unit_test_subdir_file_contents_detective') do
      results = SubdirFileContentsDetective.new.analyze(
        @evidence,
        repo_files: GithubContentAccess.new(
          'linuxfoundation/cii-best-practices-badge',
          proc { Octokit::Client.new }
        )
      )
      assert results.key?(:documentation_basics_status)
      dbs = results[:documentation_basics_status]
      assert dbs.key?(:explanation)
      assert_equal(
        'Some documentation basics file contents found.',
        dbs[:explanation]
      )
      assert dbs.key?(:value)
      assert_equal CriterionStatus::MET, dbs[:value]
    end
  end

  test 'Subdir File Contents Detective Test for no subdir' do
    VCR.use_cassette('unit_test_subdir_file_contents_detective_unmet') do
      results = SubdirFileContentsDetective.new.analyze(
        @evidence,
        repo_files: GithubContentAccess.new(
          'david-a-wheeler/test-badge-project',
          proc { Octokit::Client.new }
        )
      )
      assert results.key?(:documentation_basics_status)
      dbs = results[:documentation_basics_status]
      assert dbs.key?(:explanation)
      assert_equal(
        'No documentation basics file(s) found.',
        dbs[:explanation]
      )
      assert dbs.key?(:value)
      assert_equal CriterionStatus::UNMET, dbs[:value]
    end
  end

  test 'empty repo returns unmet results without crashing' do
    # GithubContentAccess#get_info returns [] for empty repos
    mock_repo_files = Object.new
    mock_repo_files.define_singleton_method(:blank?) { false }
    mock_repo_files.define_singleton_method(:get_info) { |_path| [] }

    results = SubdirFileContentsDetective.new.analyze(
      @evidence, repo_files: mock_repo_files
    )

    assert results.key?(:documentation_basics_status)
    dbs = results[:documentation_basics_status]
    assert_match(/No appropriate folder found/, dbs[:explanation])
    assert_equal CriterionStatus::UNMET, dbs[:value]
  end

  test 'Subdir File Contents Detective Test for no matching folder' do
    # Mock repo_files that has no matching documentation folder
    mock_repo_files = Object.new
    mock_repo_files.define_singleton_method(:blank?) { false }
    mock_repo_files.define_singleton_method(:get_info) do |path|
      if path == '/'
        # Return top-level with no doc/docs/documentation folder
        [
          { 'name' => 'README.md', 'type' => 'file' },
          { 'name' => 'src', 'type' => 'dir' },
          { 'name' => 'test', 'type' => 'dir' }
        ]
      else
        []
      end
    end

    results = SubdirFileContentsDetective.new.analyze(
      @evidence,
      repo_files: mock_repo_files
    )

    assert results.key?(:documentation_basics_status)
    dbs = results[:documentation_basics_status]
    assert dbs.key?(:explanation)
    assert_match(/No appropriate folder found/, dbs[:explanation])
    assert dbs.key?(:value)
    assert_equal CriterionStatus::UNMET, dbs[:value]
  end
end
