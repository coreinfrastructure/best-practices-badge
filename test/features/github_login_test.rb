# frozen_string_literal: true
require 'test_helper'

class GithubLoginTest < Capybara::Rails::TestCase
  scenario 'Has link to GitHub Login', js: true do
    configure_omniauth_mock unless ENV['GITHUB_PASSWORD']

    VCR.use_cassette('github_login') do
      visit '/'
      assert has_content? 'CII Best Practices Badge Program'
      click_on 'Get Your Badge Now!'
      assert has_content? 'Log in with GitHub'
      click_link 'Log in with GitHub'

      if ENV['GITHUB_PASSWORD'] # for re-recording cassettes
        fill_in 'login_field', with: 'ciitest'
        fill_in 'password', with: ENV['GITHUB_PASSWORD']
        click_on 'Sign in'
        assert has_content? 'Test BadgeApp (not for production use)'
        click_on 'Authorize application'
      end

      assert has_content? 'Signed in!'
      click_on 'Get Your Badge Now!'
      wait_for_url '/projects/new?'
      assert find(
        "option[value='https://github.com/ciitest/test-repo']"
      )
      assert find(
        "option[value='https://github.com/ciitest/cii-best-practices-badge']"
      )
      select 'ciitest/cii-best-practices-badge',
             from: 'project[repo_url]'
      click_on 'Submit GitHub Repository'
      assert has_content? 'Thanks for adding the Project! Please fill out ' \
                         'the rest of the information to get the Badge.'

      click_on 'Account'
      assert has_content? 'Profile'
      click_on 'Profile'
      assert has_content? 'CII Test'

      if ENV['GITHUB_PASSWORD'] # revoke OAuth authorization
        visit 'https://github.com/settings/applications'
        click_on 'Revoke'
        assert has_content? 'Are you sure you want to revoke authorization?'
        click_on 'I understand, revoke access'
        sleep 1
        page.evaluate_script 'window.location.reload()'
        assert has_content? 'No authorized applications'
      end
    end
  end
end
