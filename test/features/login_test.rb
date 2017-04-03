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
    assert_equal current_path, projects_path
    # Check we are redirected back to root if we try to get login again
    visit login_path
    assert_equal current_path, root_path

    visit edit_project_path(@project)

    fill_in 'project_name', with: 'It doesnt matter'
    # Below we are clicking the final save button, it has a value of ''
    click_button('Save', exact: true)
    assert_equal current_path, edit_project_path(@project)
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

    ensure_choice 'project_contribution_requirements_status_unmet' # No URL
    # Does not work on David A. Wheeler's machine:
    # assert_match QUESTION, find('#contribution_requirements_enough')['src']

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

    click_on('Submit', match: :first)
    assert_match X, find('#discussion_enough')['src']
  end
  # rubocop:enable Metrics/BlockLength

  def ensure_choice(radio_button_id)
    # Necessary because Capybara click doesn't always take the first time
    choose radio_button_id until find("##{radio_button_id}")['checked']
  end
end
