# frozen_string_literal: true

require 'test_helper'
load 'Rakefile'

class MonthlyAnnouncementTest < ActionDispatch::IntegrationTest
  # Turn off transactional fixtures for this test since we are loading
  # the fixtures database anyway. This will prevent the timestamp change
  # from spilling into other tests.
  self.use_transactional_tests = false

  test 'monthly announcement runs' do
    # Test to see that we pick the right project(s).
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

      results = ProjectsController.send :send_monthly_announcement
      assert_equal [projects(:perfect).id], results
    end
  end
end
