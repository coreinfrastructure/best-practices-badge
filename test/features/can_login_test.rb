require 'test_helper'
include ActionView::Helpers::TextHelper

class CanLoginTest < Capybara::Rails::TestCase
  CHECK = /result_symbol_check/
  DASH = /result_symbol_dash/
  QUESTION = /result_symbol_question/
  X = /result_symbol_x/

  setup do
    @user = users(:test_user)
    @project = projects(:one)
  end

  # Inspired by
  # http://toolsqa.com/selenium-webdriver/
  # scroll-element-view-selenium-javascript/
  def scroll_to_see(id)
    page.execute_script("document.getElementById('#{id}')." \
                        'scrollIntoView(false);')
  end

  scenario 'Has link to GitHub Login', js: true do
    visit login_path
    page.must_have_content('Log in with GitHub')
  end

  scenario 'Can Login and edit using custom account', js: true do
    Capybara.default_max_wait_time = 30
    visit login_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert page.has_content? 'Signed in!'

    visit edit_project_path(@project)
    choose 'project_discussion_status_unmet'
    assert_match X, page.find('#discussion_enough')['src']

    choose 'project_english_status_met'
    assert_match CHECK, page.find('#english_enough')['src']

    kill_sticky_headers # This is necessary for Chrome and Firefox
    choose 'project_contribution_status_met' # No URL given, so fails
    assert_match QUESTION, page.find('#contribution_enough')['src']

    choose 'project_contribution_requirements_status_unmet' # No URL given
    assert_match X, page.find('#contribution_requirements_enough')['src']

    click_on 'Change Control'
    assert page.has_content? 'repo_public'
    choose 'project_repo_public_status_unmet'
    assert_match X, page.find('#repo_public_enough')['src']

    # Extra assertions to deal with flapping test
    assert page.find('#project_repo_distributed_status_')['checked']
    # loop needed because selection doesn't always take the first time
    loops = 0
    while page.find('#project_repo_distributed_status_')['checked']
      puts "#{pluralize loops, 'extra loop'} required" if loops > 0
      loops += 1
      choose 'project_repo_distributed_status_unmet' # SUGGESTED, so enough
      wait_for_jquery
    end
    assert page.find('#project_repo_distributed_status_unmet')['checked']
    assert_match DASH, page.find('#repo_distributed_enough')['src']

    click_on 'Reporting'
    assert page.has_content? 'report_process'
    choose 'project_report_process_status_unmet'
    assert_match X, page.find('#report_process_enough')['src']

    click_on 'Submit'
    assert_match X, page.find('#discussion_enough')['src']
  end
end
