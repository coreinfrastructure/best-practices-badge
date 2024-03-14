# frozen_string_literal: true

# Copyright 2015-2020, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'application_system_test_case'

class GithubUserTest < ApplicationSystemTestCase
  test 'GitHub user has correct edit rights' do
    configure_omniauth_mock

    visit '/en'
    click_on 'Login'
    click_link 'Log in with GitHub'
    assert has_content? 'Logged in!'
    # Check a user can't edit a project they don't own on app or GitHub
    find('#projects_page').click
    click_on 'Pathfinder OS'
    assert_not has_content? 'Edit'
    # Check a user can edit a project they own on Github
    # We do this here because this should not require github interaction
    find('#projects_page').click
    click_on 'Mars Ascent Vehicle (MAV)'
    assert has_content? 'Edit'
    click_on 'Account'
    # Regression test, make sure GitHub users can logout
    assert has_content? 'Logout'
    click_on 'Logout'
    assert_equal '/en', current_path
  end

  # This is a regression test for problems seen by @yannickmoy in Issue #798
  test 'Alternate locale has link to GitHub Login' do
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
