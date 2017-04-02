# frozen_string_literal: true
require 'test_helper'
load 'Rakefile'

class RemindersSummaryTest < ActionDispatch::IntegrationTest
  # Turn off transactional fixtures for this test since we are loading
  # the fixtures database anyway. This will prevent the timestamp change
  # from spilling into other tests.
  self.use_transactional_tests = false

  setup do
    @user = users(:test_user)
    @admin_user = users(:admin_user)
    # Ensure the test db has its environment metadata set to test,
    # otherwise tasks farther down will fail.  New for Rails 5
    Rake::Task['db:environment:set'].invoke
    # Normalize time in order to match fixture file
    travel_to Time.zone.parse('2015-03-01T12:00:00') do
      ActiveRecord::Schema.verbose = false
      Rake::Task['db:schema:load'].reenable
      Rake::Task['db:schema:load'].invoke
      Rake::Task['db:fixtures:load'].reenable
      Rake::Task['db:fixtures:load'].invoke
    end
  end

  test 'Reminders path works for admin' do
    log_in_as(@admin_user)
    get reminders_path
    assert_response :success
    assert_template 'projects/reminders_summary'
  end

  test 'Reminders path redirects for non-admin' do
    log_in_as(@user)
    get reminders_path
    assert_redirected_to root_url
  end

  test 'Reminders path redirects for non-logged-in' do
    get reminders_path
    assert_redirected_to root_url
  end
end
