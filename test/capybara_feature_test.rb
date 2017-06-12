# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

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
