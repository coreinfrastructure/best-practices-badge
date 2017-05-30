# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class StringRefinementsNegativeTest < ActiveSupport::TestCase
  test '#met? unpatched' do
    assert_raises(NoMethodError) { 'Met'.met? }
  end

  test '#na? unpatched' do
    assert_raises(NoMethodError) { 'N/A'.na? }
  end

  test '#unknown? unpatched' do
    assert_raises(NoMethodError) { '?'.unknown }
  end

  test '#unmet? unpatched' do
    assert_raises(NoMethodError) { 'Unmet'.unmet? }
  end
end

class StringRefinementsPositiveTest < ActiveSupport::TestCase
  using StringRefinements

  test '#met?' do
    assert 'Met'.met?
    refute 'foo'.met?
  end

  test '#na?' do
    assert 'N/A'.na?
    refute 'foo'.na?
  end

  test '#unknown?' do
    assert '?'.unknown?
    refute 'foo'.unknown?
  end

  test '#unmet?' do
    assert 'Unmet'.unmet?
    refute 'foo'.unmet?
  end
end
