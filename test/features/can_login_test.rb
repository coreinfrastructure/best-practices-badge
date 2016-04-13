require 'test_helper'

class CanLoginTest < Capybara::Rails::TestCase
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
    sleep 0.5 # TODO: Wait until it's visible
  end

  scenario 'Has link to GitHub Login', js: true do
    visit login_path
    page.must_have_content('Log in with GitHub')
  end

  scenario 'Can Login and edit using custom account', js: true do
    Capybara.default_max_wait_time = 10
    visit login_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert page.has_content? 'Signed in!'

    visit edit_project_path(@project)
    scroll_to_see('project_discussion_status_unmet')
    choose 'project_discussion_status_unmet'
    scroll_to_see('discussion_enough')
    # TODO: Disabled, still can't make this work on CircleCI
    # assert page.find('#discussion_enough[src*="result_symbol_x"]')

    scroll_to_see('project_english_status_met')
    choose 'project_english_status_met'
    assert page.find('#english_enough[src*="result_symbol_check"]')

    scroll_to_see('logo')
    click_on 'Change Control'
    assert page.has_content? 'repo_public'
    scroll_to_see('project_repo_public_status_unmet')
    choose 'project_repo_public_status_unmet'
    assert page.find('#repo_public_enough[src*="result_symbol_x"]')

    # click_on 'Reporting'
    # assert page.has_content? 'report_process'
    # choose 'project_report_process_status_unmet'
    # assert page.find('#report_process_enough[src*="result_symbol_x"]')
  end
end
