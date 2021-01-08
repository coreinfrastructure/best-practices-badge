# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class AccessHomeTest < CapybaraFeatureTest
  test 'sanity' do
    visit root_path(locale: :en)
    assert has_content? 'CII Best Practices Badge Program'
  end

  scenario 'New Project link', js: true do
    visit root_path(locale: :en)
    assert has_content? 'Get Your Badge Now!'
  end

  scenario 'Header has links', js: true do
    visit root_path(locale: :en)
    assert find_link('Projects').visible?
    assert find_link('Sign Up').visible?
    assert find_link('Login').visible?
  end
end
