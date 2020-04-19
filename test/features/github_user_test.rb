# frozen_string_literal: true

# Copyright 2015-2020, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'

class GithubUserTest < CapybaraFeatureTest
  scenario 'GitHub user has correct edit rights', js: true do
    # Clean up database here and restart DatabaseCleaner.
    # This solves a transient issue if test restarts without running
    # teardown meaning the database is dirty after restart.
    DatabaseCleaner.clean
    DatabaseCleaner.start
    configure_omniauth_mock

    visit '/en'
    click_on 'Login'
    click_link 'Log in with GitHub'
    assert has_content? 'Logged in!'
    # Check a user can't edit a project they don't own on app or GitHub
    click_on 'Projects'
    click_on 'Pathfinder OS'
    refute has_content? 'Edit'
    # Check a user can edit a project they own on Github
    # We do this here because this should not require github interaction
    click_on 'Projects'
    click_on 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Edit'
    click_on 'Account'
    # Regression test, make sure GitHub users can logout
    assert has_content? 'Logout'
    click_on 'Logout'
    assert_equal '/en', current_path
  end
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
    click_on 'Si vous avez un compte GitHub, vous pouvez simplement'
    click_link 'Connectez-vous avec GitHub'
    click_on 'Account'
    # Regression test, make sure GitHub users can logout
    assert has_content? 'Logout'
    click_on 'Logout'
    assert_equal '/en', current_path
    # TODO: We should check to ensure that on login we switch to the
    # preferred_locale, no matter what it is.
    # We tested this before when "no locale" meant "English", but now that
    # *all* locales are listed (English as "en"), the original test code
    # here doesn't work.
    # assert has_content? 'Connecté !'
    # assert_equal '/fr', current_path
    # Regression test, make sure redirected correctly after login
  end
end
