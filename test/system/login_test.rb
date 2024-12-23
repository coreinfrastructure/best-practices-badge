# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'application_system_test_case'

include ActionView::Helpers::TextHelper

# rubocop:disable Metrics/ClassLength
class LoginTest < ApplicationSystemTestCase
  CHECK = /result_symbol_check/.freeze
  DASH = /result_symbol_dash/.freeze
  QUESTION = /result_symbol_question/.freeze
  X = /result_symbol_x/.freeze

  setup do
    # FastlyRails is no longer in use.
    # FastlyRails.configure do |c|
    #   c.purging_enabled = true
    # end
    @user = users(:test_user)
    @project = projects(:one)
  end

  # teardown do
  #   FastlyRails.configure do |c|
  #     c.purging_enabled = false
  #   end
  # end

  # Test this with larger integration, to increase confidence that
  # we really do reject correct local usernames with wrong passwords
  test 'Cannot login with local username and wrong password' do
    visit projects_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'WRONG_PASSWORD'
    click_button 'Log in using custom account'
    assert has_content? 'Invalid email/password combination'
    assert_equal login_path(locale: :en), current_path
  end

  # Test this with larger integration, to increase confidence that
  # we really do reject correct local usernames with blank passwords
  test 'Cannot login with local username and blank password' do
    visit projects_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: @user.email
    # NOTE: we do NOT fill in a password.
    click_button 'Log in using custom account'
    assert has_content? 'Invalid email/password combination'
    assert_equal login_path(locale: :en), current_path
  end

  # rubocop:disable Metrics/BlockLength
  test 'Can login and edit using custom account' do
    visit projects_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Logged in!'
    assert_equal projects_path(locale: :en), current_path

    visit edit_project_path(@project, locale: :en)
    assert has_content? 'This is not the production system'
    assert has_content? 'We have updated our requirements for the criterion ' \
                        'static_analysis. Please add a justification for ' \
                        'this criterion.'

    fill_in 'project_name', with: 'It does not matter'
    # Below we are clicking the final save button, it has a value of ''
    click_button('Save', exact: true)
    assert_equal edit_project_path(@project, locale: :en), current_path
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

  test 'Can Login custom where GitHub account has same email' do
    # Make GitHub account have same email address as custom account
    @github_user = users(:github_user)
    @github_user.email = @user.email
    @github_user.save!
    # Now have custom account log in.
    visit projects_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Logged in!'
    assert_equal projects_path(locale: :en), current_path
  end

  # Test if we switch to user's preferred locale on login.
  # Here we test on a path that isn't the root.
  test 'Can Login in fr locale to /projects' do
    fr_user = users(:fr_user)
    visit projects_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: fr_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Connecté !'
    assert_equal '/fr/projects', current_path
  end

  # Test login from root path.
  test 'Can Login in fr locale to top' do
    fr_user = users(:fr_user)
    visit root_path(locale: :en)
    click_on 'Login'
    fill_in 'Email', with: fr_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Connecté !'
    assert_equal '/fr', current_path
  end

  # Test login from non-english locale
  test 'Prelogin non-en locale saved on login' do
    fr_user = users(:fr_user)
    visit '/fr'
    click_on "S'identifier"
    fill_in 'Email', with: fr_user.email
    fill_in 'Mot de passe', with: 'password'
    click_button 'Connectez-vous en utilisant un compte personnalisé'
    assert has_content? 'Connecté !'
    assert_equal '/fr', current_path
  end

  def ensure_choice(radio_button_id)
    # Necessary because Capybara click doesn't always take the first time
    choose radio_button_id until find("##{radio_button_id}")['checked']
  end
end
# rubocop:enable Metrics/ClassLength
