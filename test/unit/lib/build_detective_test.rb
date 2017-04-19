# frozen_string_literal: true

require 'test_helper'

class BuildDetectiveTest < ActiveSupport::TestCase
  setup do
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'
    @evidence = Evidence.new({})
    @repo_url = "https://github.com/#{@full_name}"
  end

  test 'Build' do
    results = BuildDetective.new.analyze(
      @evidence, repo_url: @repo_url
    )
    assert results == {}
  end
end
