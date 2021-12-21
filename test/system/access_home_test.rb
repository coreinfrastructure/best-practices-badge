# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'application_system_test_case'

class AccessHomeTest < ApplicationSystemTestCase
  test 'sanity' do
    visit root_path(locale: :en)
    assert has_content? 'OpenSSF Best Practices Badge Program'
  end

  test 'New Project link' do
    visit root_path(locale: :en)
    assert has_content? 'Get Your Badge Now!'
  end

  test 'Header has links' do
    visit root_path(locale: :en)
    assert find_link('Projects').visible?
    assert find_link('Sign Up').visible?
    assert find_link('Login').visible?
  end
end
