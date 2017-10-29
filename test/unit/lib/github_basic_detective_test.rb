# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class GithubBasicDetectiveTest < ActiveSupport::TestCase
  setup do
    @full_name = 'ciitest/test-repo'
    @repo_name = 'test-repo'
    @description = 'This is for testing the CII Best Practices BadgeApp'
    @evidence = Evidence.new({})
    @repo_url = "https://github.com/#{@full_name}"
  end

  test 'Mocked GitHub retrieves name, description (no emojis), and license' do
    VCR.use_cassette('unit_test_github_basic_detective') do
      results = GithubBasicDetective.new.analyze(@evidence, repo_url: @repo_url)

      assert results.key?(:name)
      assert results[:name].key?(:value)
      assert_equal @repo_name, results[:name][:value]

      assert results.key?(:description)
      assert results[:description].key?(:value)
      assert_equal @description, results[:description][:value]

      assert results.key?(:license)
      assert results[:license].key?(:value)
      assert results[:license][:value] == 'MIT'
    end
  end
end
