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
    assert page.find('#discussion_enough[src*="result_symbol_x"]')

    choose 'project_english_status_met'
    assert page.find('#english_enough[src*="result_symbol_check"]')

    choose 'project_contribution_status_met' # No URL given, so fails
    assert page.find('#contribution_enough[src*="result_symbol_question"]')

    choose 'project_contribution_requirements_status_unmet' # No URL given
    # sleep 5 # TODO: Force delay to ensure we will find this
    assert page.find(
      '#contribution_requirements_enough[src*="result_symbol_x"]')

    click_on 'Change Control'
    assert page.has_content? 'repo_public'
    choose 'project_repo_public_status_unmet'
    assert page.find('#repo_public_enough[src*="result_symbol_x"]')

    choose 'project_repo_distributed_status_unmet' # SUGGESTED, so enough
    wait_for_jquery
    assert page.find('#repo_distributed_enough[src*="result_symbol_dash"]')

    click_on 'Reporting'
    assert page.has_content? 'report_process'
    choose 'project_report_process_status_unmet'
    assert page.find('#report_process_enough[src*="result_symbol_x"]')

    click_on 'Submit'
    assert page.find('#discussion_enough[src*="result_symbol_x"]')
  end
end
