require 'test_helper'

class CanAccessHomeTest < Capybara::Rails::TestCase
  test 'sanity' do
    visit root_path
    assert_content page, 'CII Best Practices Badge Program'
  end

  scenario 'New Project link', js: true do
    visit root_path
    page.must_have_content('Get Your Badge Now!')
  end

  scenario 'Header has links', js: true do
    visit root_path
    find_link('Projects').visible?
    find_link('Sign Up').visible?
    find_link('Login').visible?
  end
end
