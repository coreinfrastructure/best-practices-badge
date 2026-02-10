# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class RepoFilesExamineDetectiveTest < ActiveSupport::TestCase
  # Mock the file request system.
  class MockRepoFilesLicenses
    def get_info(_pattern)
      [
        {
          name: 'LICENSES', type: 'dir', html_url: './LICENSES/'
        }.with_indifferent_access
      ]
    end

    @octokit_client = true # anything other than nil
  end

  # Mock repo_files that simulates an empty GitHub repo.
  # GithubContentAccess#get_info returns [] for empty repos.
  class MockEmptyRepoFiles
    def blank?
      false
    end

    def get_info(_path)
      []
    end
  end

  test 'empty repo returns unmet results without crashing' do
    repo_files = MockEmptyRepoFiles.new
    results = RepoFilesExamineDetective.new.analyze(nil, repo_files: repo_files)

    assert results.key?(:contribution_status)
    assert_equal CriterionStatus::UNMET, results[:contribution_status][:value]
    assert results.key?(:license_location_status)
    assert_equal CriterionStatus::UNMET, results[:license_location_status][:value]
    assert results.key?(:release_notes_status)
    assert_equal CriterionStatus::UNMET, results[:release_notes_status][:value]
  end

  test 'LICENSES directory probably has licenses' do
    file_mock = MockRepoFilesLicenses.new
    results = RepoFilesExamineDetective.new.analyze(nil, repo_files: file_mock)

    assert results.key?(:license_location_status)
    assert results[:license_location_status].key?(:value)
    assert results[:license_location_status][:value] == CriterionStatus::MET
    assert results[:license_location_status][:confidence] == 3
  end
end
