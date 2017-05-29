# frozen_string_literal: true

require 'capybara_feature_test'
include ActionView::Helpers::TextHelper

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

    refute has_content? 'repo_public'
    find('#changecontrol').click
    wait_for_jquery
    assert has_content? 'repo_public'
    ensure_choice 'project_repo_public_status_unmet'
    assert_match X, find('#repo_public_enough')['src']

    assert find('#project_repo_distributed_status_')['checked']
    ensure_choice 'project_repo_distributed_status_unmet' # SUGGESTED, so enough
    assert find('#project_repo_distributed_status_unmet')['checked']
    assert_match DASH, find('#repo_distributed_enough')['src']

    refute has_content? 'report_process'
    find('#reporting').click
    wait_for_jquery
    assert has_content? 'report_process'
    ensure_choice 'project_report_process_status_unmet'
    assert_match X, find('#report_process_enough')['src']

    assert has_content? 'english'
    find('#toggle-hide-metna-criteria').click
    wait_for_jquery
    refute has_content? 'english'

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
    wait_for_jquery
    assert has_content? 'Connecté !'
    assert_equal '/fr/projects', current_path
    has_current_path? %r{\A/fr/projects/\Z}
  end

  # Test the root path.  Locale is handled differently at the root,
  # and it's a common scenario for non-en users, so make sure it works.
  scenario 'Can Login in fr locale to top', js: true do
    @fr_user = users(:fr_user)
    visit root_path
    click_on 'Login'
    fill_in 'Email', with: @fr_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    wait_for_jquery
    assert has_content? 'Connecté !'
    has_current_path? %r{/\?locale=fr\Z}, url: true
  end

  def ensure_choice(radio_button_id)
    # Necessary because Capybara click doesn't always take the first time
    choose radio_button_id until find("##{radio_button_id}")['checked']
  end
end
