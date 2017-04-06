# frozen_string_literal: true
source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'bcrypt', '3.1.11' # Security - for salted hashed interated passwords
gem 'bootstrap-sass', '3.3.7'
gem 'bootstrap-social-rails', '4.12.0'
gem 'bootstrap-will_paginate', '0.0.11'
gem 'bootstrap_form', '2.6.0'
gem 'chartkick', '2.2.3' # Chart project_stats
gem 'coffee-rails', '4.2.1' # Support CoffeeScript (Javascript preprocessor)
gem 'faker', '1.7.3'
# Fastly master is locked to a railties version
gem 'fastly-rails', '0.8.0'
gem 'font-awesome-rails', '4.7.0.1'
gem 'github_api', '0.14.5'
gem 'imagesLoaded_rails', '4.1.0' # JavaScript - enable wait for image load
gem 'jbuilder', '2.6.3'
gem 'jquery-rails', '4.3.1' # JavaScript jQuery library (for Rails)
# gem 'jquery-turbolinks' # Make turbolinks work with jQuery
gem 'jquery-ui-rails', '6.0.1' # JavaScript jQueryUI library (for Rails)
gem 'octokit', '4.6.2' # GitHub's official Ruby API
gem 'omniauth-github', '1.2.3' # Authentication to GitHub (get project info)
gem 'paper_trail', '7.0.0' # Record previous versions of project data
gem 'pg', '0.20.0' # PostgreSQL database, used for data storage
gem 'pg_search', '2.0.1' # PostgreSQL full-text search
gem 'puma', '3.8.2' # Faster webserver; recommended by Heroku
gem 'rails', '5.0.2' # Our web framework
gem 'redcarpet', '3.4.0' # Process markdown in form textareas (justifications)
gem 'sass-rails', '5.0.6'
gem 'secure_headers', '3.6.2' # Add hardening measures to HTTP headers
# gem 'turbolinks', '5.0.1' # Speed UI access
gem 'uglifier', '3.1.12'
gem 'will_paginate', '3.1.5'

group :development, :test do
  gem 'awesome_print', '1.7.0'
  gem 'bullet', '5.5.1'
  gem 'bundler-audit', '0.5.0'
  gem 'database_cleaner', '1.5.3' # Cleans up database between tests
  gem 'dotenv-rails', '2.2.0'
  gem 'eslintrb', '2.1.0'
  gem 'json', '1.8.6'
  gem 'license_finder', '3.0.0'
  gem 'mdl', '0.4.0'
  gem 'pronto', '0.8.2'
  gem 'pronto-brakeman', '0.8.0'
  gem 'pronto-eslint', '0.8.0'
  gem 'pronto-rails_best_practices', '0.8.0'
  gem 'pronto-rubocop', '0.8.0'
  gem 'pry-byebug', '3.4.2'
  gem 'rubocop', '0.47.1' # Style checker.  Changes can cause test failure
  gem 'ruby-graphviz', '1.2.3' # This is used for bundle viz
  gem 'spring', '2.0.1'
  gem 'vcr', '3.0.3' # Record network responses for later test reuse
  gem 'yaml-lint', '0.0.9' # Check YAML file syntax
end

group :development do
  # gem 'fasterer', '0.3.2' # Provide speed recommendations - run 'fasterer'
  # Waiting for Ruby 2.4 support: https://github.com/seattlerb/ruby_parser/issues/239
  gem 'rails_db', '1.5.0' # Enable localhost:3000/rails/db debugging
  gem 'traceroute', '0.5.0' # Adds 'rake traceroute' command to check routes
  gem 'web-console', '3.5.0'
end

group :test do
  gem 'capybara-slow_finder_errors', '0.1.4' # warn if test waits for timeout
  gem 'chromedriver-helper', '1.1.0'
  gem 'codecov', '0.1.10', require: false
  gem 'minitest-rails-capybara', '3.0.1', require: false
  gem 'minitest-retry', '0.1.8', require: false # Avoid Capybara false positives
  gem 'poltergeist', '1.14.0', require: false
  gem 'rails-controller-testing', '1.0.1'
  gem 'selenium-webdriver', '3.3.0', require: false
  gem 'simplecov', '0.14.1', require: false
  gem 'webmock', '2.3.2', require: false
end

group :production do
  gem 'rails_12factor', '0.0.3'
  # Historically we used this gem to compress (to reduce network load):
  # gem 'heroku_rails_deflate', '1.0.3'
  # Removed according to http://stackoverflow.com/a/39550697/1935918
  # (it has not yet been updated to work with Rails 5).  Rack has a
  # built-in compression mechanism, which we use in production instead.
  gem 'rack-timeout', '0.4.2' # Timeout; https://github.com/heroku/rack-timeout
end
