# frozen_string_literal: true

require 'test_helper'

class SubdirFileContentsDetectiveTest < ActiveSupport::TestCase
  def setup
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
      assert_equal 'Met', dbs[:value]
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
      assert_equal 'Unmet', dbs[:value]
    end
  end
end
