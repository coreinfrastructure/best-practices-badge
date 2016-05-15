# frozen_string_literal: true
require 'test_helper'

class NameFromUrlDetectiveTest < ActiveSupport::TestCase
  def setup
    @evidence = Evidence.new({})
  end

  test 'Simple name in project URL domain name is detected' do
    results = NameFromUrlDetective.new.analyze(
      @evidence, homepage_url: 'http://www.sendmail.com'
    )

    assert results.key?(:name)
    assert results[:name].key?(:value)
    assert_equal 'sendmail', results[:name][:value]
    assert_equal 1, results[:name][:confidence]
  end

  test 'Simple name in project URL tail is detected' do
    results = NameFromUrlDetective.new.analyze(
      @evidence, homepage_url: 'http://www.dwheeler.com/flawfinder'
    )

    assert results.key?(:name)
    assert results[:name].key?(:value)
    assert_equal 'flawfinder', results[:name][:value]
    assert_equal 1, results[:name][:confidence]
  end

  test 'Simple name in repo URL tail is detected' do
    results = NameFromUrlDetective.new.analyze(
      @evidence,
      repo_url: 'https://github.com/linuxfoundation/cii-best-practices-badge'
    )

    assert results.key?(:name)
    assert results[:name].key?(:value)
    assert_equal 'cii-best-practices-badge', results[:name][:value]
    assert_equal 1, results[:name][:confidence]
  end
end
