# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class GithubContentAccessTest < ActiveSupport::TestCase
  # Mock Octokit client that raises NotFound (simulates empty repo)
  class MockOctokitEmpty
    def contents(_fullname, **)
      raise Octokit::NotFound
    end
  end

  # Mock Octokit client that returns normal contents
  class MockOctokitNormal
    CONTENTS = [
      { 'name' => 'README.md', 'type' => 'file', 'size' => 100 }
    ].freeze

    def contents(_fullname, **)
      CONTENTS
    end
  end

  test 'get_info returns empty array when repo is empty (Octokit::NotFound)' do
    access = GithubContentAccess.new(
      'owner/empty-repo', proc { MockOctokitEmpty.new }
    )
    result = access.get_info('/')

    assert_equal [], result
  end

  test 'get_info returns contents normally for non-empty repo' do
    access = GithubContentAccess.new(
      'owner/some-repo', proc { MockOctokitNormal.new }
    )
    result = access.get_info('/')

    assert_equal MockOctokitNormal::CONTENTS, result
  end
end
