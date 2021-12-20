# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class BadgeTest < ActiveSupport::TestCase
  test 'Badge should have 103 instances' do
    assert_equal 103, Badge.count
  end

  test 'First badge should be 0%' do
    assert_equal '0%', Badge.first.to_s[-19..-18]
  end

  test '88% Badge matches fixture file' do
    assert_equal contents('badge-88.svg'), Badge[88].to_s
  end

  test 'passing Badge matches fixture file' do
    assert_equal contents('badge-passing.svg'), Badge['passing'].to_s
  end

  test ' silver badge matches silver from fixture file' do
    assert_equal contents('badge-silver.svg'), Badge['silver'].to_s
  end

  test ' gold badge matches gold from fixture file' do
    assert_equal contents('badge-gold.svg'), Badge['gold'].to_s
  end

  test 'Badge requires integer < 100 parameters' do
    assert_raise(ArgumentError) { Badge[5.5] }
    assert_raise(ArgumentError) { Badge[100] }
  end
end
