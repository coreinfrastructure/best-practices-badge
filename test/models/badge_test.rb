require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  test 'Badge should have 101 instances' do
    assert_equal 101, Badge.count
  end

  test 'First badge should be 0%' do
    assert_equal '0%', Badge.first.to_s[-19..-18]
  end

  test '88% Badge matches fixture file' do
    assert_equal contents('badge-88.svg'), Badge[88].to_s
  end

  test '100% Badge matches fixture file' do
    assert_equal contents('badge-100.svg'), Badge[100].to_s
  end
end
