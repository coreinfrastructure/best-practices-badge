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

  test 'LICENSES directory probably has licenses' do
    file_mock = MockRepoFilesLicenses.new
    results = RepoFilesExamineDetective.new.analyze(nil, repo_files: file_mock)

    assert results.key?(:license_location_status)
    assert results[:license_location_status].key?(:value)
    assert results[:license_location_status][:value] == 'Met'
    assert results[:license_location_status][:confidence] == 3
  end
end
