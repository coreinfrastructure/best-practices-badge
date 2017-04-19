# frozen_string_literal: true

# We use DatabaseCleaner to clean up database between capybara tests.
require 'test_helper'
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

class CapybaraFeatureTest < Capybara::Rails::TestCase
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
end
