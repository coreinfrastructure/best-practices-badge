require 'test_helper'

class CanLoginTest < Capybara::Rails::TestCase
  scenario 'Has link to GitHub Login', js: true do
    visit login_path
    page.must_have_content('Log in with GitHub')
  end

  scenario 'Can Login using custom account', js: true do
    visit login_path
    fill_in 'Email', with: 'test@example.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert page.has_content? 'Signed in!'
  end
end
