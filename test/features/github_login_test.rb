
require 'test_helper'

class GithubLoginTest < Capybara::Rails::TestCase
  scenario 'Has link to GitHub Login', js: true do
    VCR.use_cassette('github_login') do
      p current_url
      visit '/'
      p current_url
      assert has_content? 'CII Best Practices Badge Program'
      click_on 'Get Your Badge Now!'
      p current_url
      assert has_content? 'Log in with GitHub'
      p current_url
      p ENV['GITHUB_KEY']
      click_link 'Log in with GitHub'
      fill_in 'login_field', with: 'notmylogin'
      fill_in 'password', with: 'notmypassword'
      click_on 'Sign in'
      assert has_content? 'Authorize application'
      p current_url
      click_on 'Authorize application'
      assert has_content? 'Signed in!'
      p current_url
      click_on 'Get Your Badge Now!'
      p current_url
      assert find(
        "option[value='https://github.com/ciibot/cii-best-practices-badge']")
      select('https://github.com/ciibot/cii-best-practices-badge',
             from: 'project_repo_url')
      click_link 'Submit Github Repository'
      assert has_content 'Thanks for adding the Project! Please fill out the ' \
                         'rest of the information to get the Badge.'
    end
  end
end
