source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'autosize-rails', '1.18.17' # Improve HTML textareas
gem 'bcrypt', '3.1.11' # Security - for salted hashed interated passwords
gem 'bootstrap-sass', '3.3.6'
gem 'bootstrap-social-rails', '4.12.0'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'bootstrap_form', '2.3.0'
gem 'faker', '1.6.3'
gem 'fastly-rails', '0.5.0' # Use Fastly CDN
gem 'github_api', '0.13.1'
gem 'imagesLoaded_rails', '4.1.0' # Javascript - enable wait for image load
gem 'jbuilder', '2.4.1'
gem 'jquery-rails', '4.1.1' # Javascript jQuery library (for Rails)
gem 'jquery-ui-rails', '5.0.5' # Javascript jQueryUI library (for Rails)
gem 'redcarpet', '3.3.4' # Process markdown in form textareas (justifications)
gem 'octokit', '4.3.0' # GitHub's official Ruby API
gem 'omniauth-github', '1.1.2' # Authentication to GitHub (get project info)
gem 'paper_trail', '4.1.0' # Record previous versions of project data
gem 'pg', '0.18.4' # PostgreSQL database, used for data storage
gem 'puma', '3.4.0' # Faster webserver; recommended by Heroku
gem 'rack-timeout', '0.4.2' # Timeout per https://github.com/heroku/rack-timeout
gem 'rails', '4.2.6' # Our web framework
gem 'sass-rails', '5.0.4'
gem 'secure_headers', '3.2.0' # Harden app security using HTTP headers
gem 'turbolinks', '2.5.3' # Speed UI access
gem 'jquery-turbolinks'   # Make turbolinks work with jQuery
gem 'uglifier', '3.0.0'
gem 'will_paginate', '3.1.0'
gem 'ransack', '1.7.0' # Make search available in all.

group :development, :test do
  gem 'awesome_print', '1.6.1'
  gem 'bullet', '5.0.0'
  gem 'bundler-audit', '0.5.0'
  gem 'ruby-graphviz', '1.2.2'
  gem 'dotenv-rails', '2.1.1'
  # Following line addresses https://github.com/ocke/eslintrb/pull/5
  gem 'eslintrb', git: 'https://github.com/dankohn/eslintrb.git', ref: '306932f'
  gem 'license_finder'
  gem 'mdl', '0.3.1'
  gem 'pronto', '0.6.0'
  gem 'pronto-brakeman', '0.6.0'
  gem 'pronto-eslint', '0.6.1'
  gem 'pronto-rails_best_practices', '0.6.0'
  gem 'pronto-rubocop', '0.6.2'
  gem 'pry-byebug', '3.3.0'
  gem 'quiet_assets', '1.1.0'
  gem 'spring', '1.7.1'
  gem 'vcr', '3.0.1' # Record network responses for later test reuse
  gem 'yaml-lint', '0.0.7' # Check YAML file syntax
end

group :development do
  gem 'fasterer', '0.3.2' # Provide speed recommendations - run 'fasterer'
  gem 'rails_db', '1.1.1' # Enable localhost:3000/rails/db debugging
  gem 'traceroute', '0.5.0' # Adds 'rake traceroute' command to check routes
  gem 'web-console', '3.1.1'
end

group :test do
  gem 'chromedriver-helper', '1.0.0'
  gem 'coveralls', '0.8.13', require: false
  gem 'm', '1.4.2' # Run test/unit tests by line number
  gem 'minitest-rails-capybara', '2.1.1', require: false
  gem 'minitest-retry', '0.1.4', require: false # Avoid Capybara false positives
  gem 'poltergeist', '1.9.0', require: false
  gem 'selenium-webdriver', '2.53.0', require: false
  gem 'simplecov', '0.11.2', require: false
  gem 'webmock', '1.24.4', require: false
end

group :production do
  gem 'rails_12factor', '0.0.3'
  gem 'heroku_rails_deflate', '1.0.3' # Compress (reduces network load)
end
