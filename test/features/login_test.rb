# frozen_string_literal: true
require 'test_helper'
include ActionView::Helpers::TextHelper

class LoginTest < Capybara::Rails::TestCase
  CHECK = /result_symbol_check/
  DASH = /result_symbol_dash/
  QUESTION = /result_symbol_question/
  X = /result_symbol_x/

  setup do
    @user = users(:test_user)
    @project = projects(:one)
  end

  scenario 'Has link to GitHub Login', js: true do
    visit login_path
    assert has_content? 'Log in with GitHub'
  end

  scenario 'Can Login and edit using custom account', js: true do
    visit login_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert has_content? 'Signed in!'

    visit edit_project_path(@project)
    kill_sticky_headers # This is necessary for Chrome and Firefox

    ensure_choice 'project_discussion_status_unmet'
    assert_match X, find('#discussion_enough')['src']

    ensure_choice 'project_english_status_met'
    assert_match CHECK, find('#english_enough')['src']

    ensure_choice 'project_contribution_status_met' # No URL given, so fails
    assert_match QUESTION, find('#contribution_enough')['src']

    ensure_choice 'project_contribution_requirements_status_unmet' # No URL
    assert_match X, find('#contribution_requirements_enough')['src']

    click_on 'Change Control'
    assert has_content? 'repo_public'
    ensure_choice 'project_repo_public_status_unmet'
    assert_match X, find('#repo_public_enough')['src']

    assert find('#project_repo_distributed_status_')['checked']
    ensure_choice 'project_repo_distributed_status_unmet' # SUGGESTED, so enough
    assert find('#project_repo_distributed_status_unmet')['checked']
    assert_match DASH, find('#repo_distributed_enough')['src']

    click_on 'Reporting'
    assert has_content? 'report_process'
    ensure_choice 'project_report_process_status_unmet'
    assert_match X, find('#report_process_enough')['src']

    click_on 'Submit'
    assert_match X, find('#discussion_enough')['src']
  end

  def ensure_choice(radio_button_id)
    # Necessary because Capybara click doesn't always take the first time
    choose radio_button_id until find("##{radio_button_id}")['checked']
  end
end
