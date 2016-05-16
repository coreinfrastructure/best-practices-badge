# frozen_string_literal: true
require 'test_helper'

class AccessHomeTest < Capybara::Rails::TestCase
  test 'sanity' do
    visit root_path
    assert has_content? 'CII Best Practices Badge Program'
  end

  scenario 'New Project link', js: true do
    visit root_path
    assert has_content? 'Get Your Badge Now!'
  end

  scenario 'Header has links', js: true do
    visit root_path
    assert find_link('Projects').visible?
    assert find_link('Sign Up').visible?
    assert find_link('Login').visible?
  end
end
