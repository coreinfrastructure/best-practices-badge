# frozen_string_literal: true

require 'test_helper'
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

class RakeTaskTest < ActiveSupport::TestCase
  # When using DatabaseCleaner, transactional fixtures must be off.
  self.use_transactional_tests = false

  setup do
    # Start DatabaseCleaner before each test.
    DatabaseCleaner.start
  end

  teardown do
    # Clean up the database with DatabaseCleaner after each test.
    DatabaseCleaner.clean
  end

  test 'regression test for rake reminders' do
    assert_equal 1, Project.projects_to_remind.size
    result = system 'rake reminders >/dev/null'
    assert result
    assert_equal 0, Project.projects_to_remind.size
  end
end
