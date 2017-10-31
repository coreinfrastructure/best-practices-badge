# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'capybara_feature_test'
include ActionView::Helpers::TextHelper

# rubocop:disable Metrics/ClassLength
class LoginTest < CapybaraFeatureTest
  CHECK = /result_symbol_check/
  DASH = /result_symbol_dash/
  QUESTION = /result_symbol_question/
  X = /result_symbol_x/

  setup do
    FastlyRails.configure do |c|
      c.purging_enabled = true
    end
    @user = users(:test_user)
    @project = projects(:one)
  end

  teardown do
    FastlyRails.configure do |c|
      c.purging_enabled = false
    end
  end

  # Test this with larger integration, to increase confidence that
  # we really do reject correct local usernames with wrong passwords
  scenario 'Cannot login with local username and wrong password', js: false do
    visit projects_path
    click_on 'Login'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'WRONG_PASSWORD'
    click_button 'Log in using custom account'
    assert has_content? 'Invalid email/password combination'
    assert_equal login_path, current_path
  end

  # Test this with larger integration, to increase confidence that
  # we really do reject correct local usernames with blank passwords
  scenario 'Cannot login with local username and blank password', js: false do
    visit projects_path
    click_on 'Login'
    fill_in 'Email', with: @user.email
    # Note: we do NOT fill in a password.
    click_button 'Log in using custom account'
    assert has_content? 'Invalid email/password combination'
    assert_equal login_path, current_path
  end

  # rubocop:disable Metrics/BlockLength
  scenario 'Can Login and edit using custom account', js: true do
    visit projects_path
    click_on 'Login'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Signed in!'
    assert_equal projects_path, current_path

    visit edit_project_path(@project, locale: nil)
    assert has_content? 'This is not the production system'
    assert has_content? 'We have updated our requirements for the criterion ' \
                        '<a href="#static_analysis">static_analysis</a>. ' \
                        'Please add a justification for '\
                        'this criterion.'

    fill_in 'project_name', with: 'It doesnt matter'
    # Below we are clicking the final save button, it has a value of ''
    click_button('Save', exact: true)
    assert_equal edit_project_path(@project, locale: nil), current_path
    assert has_content? 'Project was successfully updated.'
    # TODO: Get the clicking working again with capybara.
    # Details: If we expand all panels first and dont click this test passes.
    #          If we instead click each section, Capybara has issues not seen
    #          in real world scenarios, mainly it doesn't correctly identify
    #          an elements parents, leading to errors.
    kill_sticky_headers # This is necessary for Chrome and Firefox
    ensure_choice 'project_discussion_status_unmet'
    assert_match X, find('#discussion_enough')['src']

    ensure_choice 'project_english_status_met'
    assert_match CHECK, find('#english_enough')['src']

    ensure_choice 'project_contribution_status_met' # No URL given, so fails
    assert_match QUESTION, find('#contribution_enough')['src']
    fill_in 'project_contribution_justification',
            with: 'For more information see: http://www.example.org/'
    wait_for_jquery
    assert_match CHECK, find('#contribution_enough')['src']

    ensure_choice 'project_contribution_requirements_status_unmet' # No URL
    assert_match QUESTION, find('#contribution_requirements_enough')['src']

    refute_selector(:css, '#repo_public')
    find('#changecontrol').click
    wait_for_jquery
    assert_selector(:css, '#repo_public')
    ensure_choice 'project_repo_public_status_unmet'
    assert_match X, find('#repo_public_enough')['src']

    assert find('#project_repo_distributed_status_')['checked']
    ensure_choice 'project_repo_distributed_status_unmet' # SUGGESTED, so enough
    assert find('#project_repo_distributed_status_unmet')['checked']
    assert_match DASH, find('#repo_distributed_enough')['src']

    refute_selector(:css, '#report_process')
    find('#toggle-expand-all-panels').click
    wait_for_jquery
    assert_selector(:css, '#report_process')
    ensure_choice 'project_report_process_status_unmet'
    assert_match X, find('#report_process_enough')['src']

    assert_selector(:css, '#english')
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute_selector(:css, '#english')

    click_on('Submit', match: :first)
    assert_match X, find('#discussion_enough')['src']
  end
  # rubocop:enable Metrics/BlockLength

  # Test if we switch to user's preferred locale on login.
  # Here we test on a path that isn't the root.
  # We have to implement these tests in (slower) integration testing.
  # That's because the test infrastructure normally takes shortcuts in the
  # login functionality to speed login. Those shortcuts speed test execution
  # in general, but they also mean that testing this specific functionality
  # won't work because of its inadequate simulation of the real situation
  # (and thus requires a full integration test instead).
  scenario 'Can Login in fr locale to /projects', js: true do
    @fr_user = users(:fr_user)
    visit projects_path
    click_on 'Login'
    fill_in 'Email', with: @fr_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Connecté !'
    assert_equal '/fr/projects', current_path
  end

  # Test login from root path.
  scenario 'Can Login in fr locale to top', js: true do
    @fr_user = users(:fr_user)
    visit root_path
    click_on 'Login'
    fill_in 'Email', with: @fr_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Connecté !'
    assert_equal '/fr/', current_path
  end

  # Test login from non-english locale
  scenario 'Prelogin non-en locale saved on login', js: true do
    visit '/fr/'
    click_on "S'identifier"
    fill_in 'Email', with: @user.email
    fill_in 'Mot de passe', with: 'password'
    click_button 'Connectez-vous en utilisant un compte personnalisé'
    assert has_content? 'Connecté !'
    assert_equal '/fr/', current_path
  end

  def ensure_choice(radio_button_id)
    # Necessary because Capybara click doesn't always take the first time
    choose radio_button_id until find("##{radio_button_id}")['checked']
  end
end
