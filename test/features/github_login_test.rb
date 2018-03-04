# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class GithubLoginTest < CapybaraFeatureTest
  # rubocop:disable Metrics/BlockLength
  scenario 'Has link to GitHub Login', js: true do
    # Clean up database here and restart DatabaseCleaner.
    # This solves a transient issue if test restarts without running
    # teardown meaning the database is dirty after restart.
    DatabaseCleaner.clean
    DatabaseCleaner.start
    configure_omniauth_mock unless ENV['GITHUB_PASSWORD']

    VCR.use_cassette('github_login', allow_playback_repeats: true) do
      visit '/en'
      assert has_content? 'CII Best Practices Badge Program'
      click_on 'Get Your Badge Now!'
      assert_equal new_project_path(locale: :en), current_path
      assert has_content? 'Log in with GitHub'
      num = ActionMailer::Base.deliveries.size
      click_link 'Log in with GitHub'

      # When re-recording cassetes you must use DRIVER=chrome
      # Github has an anti bot mechanism that requires real mouse movement
      # to authorize an application.
      if ENV['GITHUB_PASSWORD'] # for re-recording cassettes
        find_field id: 'login_field' # Make sure field exists first
        fill_in 'login_field', with: 'ciitest'
        fill_in 'password', with: ENV['GITHUB_PASSWORD']
        click_on 'Sign in'
        assert page.has_content?('Test BadgeApp (not for production use)')
        click_on 'Authorize dankohn'
      end

      assert_equal num + 1, ActionMailer::Base.deliveries.size
      assert has_content? 'Logged in!'
      # Regression test, make sure redirected correctly after login
      assert_equal new_project_path, current_path
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

      assert_equal num + 2, ActionMailer::Base.deliveries.size
      click_on 'Account'
      assert has_content? 'Profile'
      click_on 'Profile'
      assert has_content? 'Core Infrastructure Initiative Best Practices Badge'
      # Next two lines give a quick coverage increase in session_helper.rb
      click_on 'Projects'
      click_on 'Pathfinder OS'
      refute has_content? 'Edit'
      click_on 'Account'
      # Regression test, make sure GitHub users can logout
      assert has_content? 'Logout'
      click_on 'Logout'
      assert_equal root_path(locale: :en), current_path

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
  # rubocop:enable Metrics/BlockLength

  # This is a regression test for problems seen by @yannickmoy in Issue #798
  scenario 'Alternate locale has link to GitHub Login', js: true do
    # Clean up database here and restart DatabaseCleaner.
    # This solves a transient issue if test restarts without running
    # teardown meaning the database is dirty after restart.
    DatabaseCleaner.clean
    DatabaseCleaner.start
    configure_omniauth_mock

    visit '/fr/signup'
    assert has_content? "S'inscrire"
    click_on 'Si vous avez un compte GitHub, vous pouvez simplement ' \
              + "l'utiliser pour vous connectez."
    click_link 'Connectez-vous avec GitHub'
    assert has_content? 'Connecté !'
    # Regression test, make sure redirected correctly after login
    assert_equal '/fr/', current_path
  end
end
