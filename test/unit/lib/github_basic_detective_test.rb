# frozen_string_literal: true
require 'test_helper'

class GithubBasicDetectiveTest < ActiveSupport::TestCase
  def setup
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'
    @evidence = Evidence.new({})
    @repo_url = "https://github.com/#{@full_name}"
  end

  test 'Mocked GitHub retrieves our name and license' do
    VCR.use_cassette('unit_test_github_basic_detective') do
      results = GithubBasicDetective.new.analyze(@evidence, repo_url: @repo_url)

      assert results.key?(:name)
      assert results[:name].key?(:value)
      assert results[:name][:value] == @human_name

      assert results.key?(:license)
      assert results[:license].key?(:value)
      assert results[:license][:value] == 'MIT'
    end
  end
end
