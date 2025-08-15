# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be
# available to Rake.

require File.expand_path('config/application', __dir__)

# Guard against loading tasks multiple times to prevent constant warnings

unless Rake::Task.task_defined?('stats') || Rake::Task.task_defined?('environment') || defined?(STATS_DIRECTORIES)
  Rails.application.load_tasks
end
