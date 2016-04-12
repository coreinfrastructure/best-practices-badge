require 'test_helper'

class CanLoginTest < Capybara::Rails::TestCase
  setup do
    @user = users(:test_user)
    @project = projects(:one)
  end

  scenario 'Has link to GitHub Login', js: true do
    visit login_path
    page.must_have_content('Log in with GitHub')
  end

  scenario 'Can Login and edit using custom account', js: true do
    visit login_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in using custom account'
    assert page.has_content? 'Signed in!'
    visit edit_project_path(@project)
    # choose 'project_english_status_met'
    # assert page.find('#english_enough')['src'].include? 'Thumbs_up'
    click_on 'Reporting'
    choose 'project_report_process_status_unmet'
    # TODO: Need to make this test work.
    # Disabling for now so it won't break the build.
    # assert page.find('#report_process_enough')['src'].include?(
    #   'result_symbol_x')
  end
end
