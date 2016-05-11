require 'test_helper'

class GithubLoginTest < Capybara::Rails::TestCase
  scenario 'Has link to GitHub Login', js: true do
    configure_omniauth_mock unless ENV['TEST_GITHUB_PASSWORD']

    VCR.use_cassette('github_login') do
      visit '/'
      assert has_content? 'CII Best Practices Badge Program'
      click_on 'Get Your Badge Now!'
      assert has_content? 'Log in with GitHub'
      click_link 'Log in with GitHub'

      if ENV['TEST_GITHUB_PASSWORD']
        fill_in 'login_field', with: 'ciitest'
        fill_in 'password', with: ENV['TEST_GITHUB_PASSWORD']
        click_on 'Sign in'
      end

      assert has_content? 'Signed in!'
      click_on 'Get Your Badge Now!'
      wait_for_url '/projects/new?'
      assert find(
        "option[value='https://github.com/ciitest/test-repo']")
      assert find(
        "option[value='https://github.com/ciitest/cii-best-practices-badge']")
      select 'ciitest/cii-best-practices-badge',
             from: 'project[repo_url]'
      click_on 'Submit GitHub Repository'
      assert has_content? 'Thanks for adding the Project! Please fill out ' \
                         'the rest of the information to get the Badge.'
    end
  end
end
