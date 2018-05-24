# frozen_string_literal: true

# This lists all gems we directly depend on.
# We depend on explicit version numbers (so we can control upgrade times).
# Any one gem is listed no more than once (to prevent referring to
# different version numbers in different environments).

source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'bcrypt', '3.1.12' # Security - for salted hashed interated passwords
gem 'bootstrap-sass', '3.3.7'
gem 'bootstrap-social-rails', '4.12.0'
gem 'bootstrap-will_paginate', '1.0.0'
gem 'bootstrap_form', '2.7.0'
gem 'chartkick', '2.3.4' # Chart project_stats
gem 'coffee-rails', '4.2.2', require: false # CoffeeScript Javascript preproc
gem 'fastly-rails', '0.8.0'
gem 'font-awesome-rails', '4.7.0.4'
gem 'http_accept_language', '2.1.1' # Determine user's preferred locale
gem 'imagesLoaded_rails', '4.1.0' # JavaScript - enable wait for image load
gem 'jbuilder', '2.7.0'
gem 'jquery-rails', '4.3.3' # JavaScript jQuery library (for Rails)
gem 'jquery-ui-rails', '6.0.1' # JavaScript jQueryUI library (for Rails)
gem 'lograge', '0.10.0' # Simplify logs
gem 'mail', '2.7.0' # Ruby mail handler
gem 'octokit', '4.9.0' # GitHub's official Ruby API
gem 'omniauth-github', '1.3.0' # Authentication to GitHub (get project info)
gem 'openssl', '2.1.1' # Encryption routines (e.g., for email addresses)
gem 'paleta', '0.3.0' # Color manipulation, used for badges
gem 'paper_trail', '9.0.1' # Record previous versions of project data
gem 'pg', '1.0.0' # PostgreSQL database, used for data storage
gem 'pg_search', '2.1.2' # PostgreSQL full-text search
gem 'puma', '3.11.4' # Faster webserver; recommended by Heroku
gem 'rack-cors', '1.0.2' # Enable CORS so JavaScript clients can get JSON
gem 'rails', '5.1.6' # Our web framework
gem 'rails-i18n', '5.1.1' # Localizations for Rails built-ins
gem 'redcarpet', '3.4.0' # Process markdown in form textareas (justifications)
gem 'sass-rails', '5.0.7', require: false
gem 'scout_apm', '2.4.11' # Monitor for memory leaks
gem 'secure_headers', '6.0.0' # Add hardening measures to HTTP headers
gem 'uglifier', '4.1.10', require: false # Minify JavaScript
gem 'will-paginate-i18n', '0.1.15' # Provide will-paginate translations
gem 'will_paginate', '3.1.6' # Paginate results (next/previous)

group :development, :test do
  gem 'awesome_print', '1.8.0' # Pretty print Ruby objects
  gem 'bullet', '5.7.5' # Avoid n+1 queries
  gem 'bundler-audit', '0.6.0'
  gem 'database_cleaner', '1.7.0' # Cleans up database between tests
  gem 'dotenv-rails', '2.4.0'
  gem 'eslintrb', '2.1.0'
  gem 'json', '2.1.0'
  gem 'license_finder', '5.2.0'
  gem 'mdl', '0.4.0'
  gem 'pronto', '0.9.5'
  gem 'pronto-brakeman', '0.9.1'
  gem 'pronto-eslint', '0.9.1'
  gem 'pronto-rails_best_practices', '0.9.0'
  gem 'pronto-rubocop', '0.9.0'
  gem 'rubocop', '0.52.1' # Style checker.  Changes can cause test failure
  gem 'ruby-graphviz', '1.2.3' # This is used for bundle viz
  gem 'spring', '2.0.2' # Preloads app so console, rake, and tests run faster
  gem 'vcr', '4.0.0' # Record network responses for later test reuse
  gem 'yaml-lint', '0.0.10' # Check YAML file syntax
end

# The "fake_production" environment is very much like production, however,
# we enable a few debug tools to help us find "production-only" bugs.
group :fake_production, :development, :test do
  gem 'pry-byebug', '3.6.0'
end

group :development do
  gem 'bootsnap', '1.3.0' # Speed up boot via caches
  # gem 'fasterer', '0.3.2' # Provide speed recommendations - run 'fasterer'
  # Waiting for Ruby 2.4 support: https://github.com/seattlerb/ruby_parser/issues/239
  gem 'traceroute', '0.6.1' # Adds 'rake traceroute' command to check routes
  gem 'translation', '1.14' # translation.io - translation service
  gem 'web-console', '3.6.2' # Debugging tool for Ruby on Rails apps
end

group :test do
  gem 'capybara-slow_finder_errors', '0.1.4', require: false
  gem 'chromedriver-helper', '1.2.0', require: false
  gem 'codecov', '0.1.10', require: false
  gem 'minitest-rails-capybara', '3.0.1', require: false
  gem 'minitest-reporters', '1.2.0', require: false
  gem 'minitest-retry', '0.1.9', require: false # Avoid Capybara false positives
  gem 'poltergeist', '1.18.0', require: false
  gem 'rails-controller-testing', '1.0.2' # need to require this one
  gem 'selenium-webdriver', '3.12.0', require: false
  gem 'simplecov', '0.16.1', require: false
  gem 'webmock', '3.4.1', require: false
end

group :production do
  gem 'rack-timeout', '0.4.2' # Timeout; https://github.com/heroku/rack-timeout
  gem 'rails_12factor', '0.0.3'
end
