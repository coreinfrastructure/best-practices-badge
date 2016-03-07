source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'autosize-rails', '1.18.17' # Improve HTML textareas
gem 'bcrypt', '3.1.10' # Security - for salted hashed interated passwords
gem 'bootstrap-sass', '3.3.6'
gem 'bootstrap-social-rails', '4.8.0'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'bootstrap_form', '2.3.0'
gem 'faker', '1.6.3'
gem 'fastly-rails', '0.4.1' # Use Fastly CDN
gem 'github_api', '0.13.0'
gem 'jbuilder', '2.4.1'
gem 'jquery-rails', '4.1.0' # Javascript jQuery library (for Rails)
gem 'jquery-ui-rails', '5.0.5' # Javascript jQueryUI library (for Rails)
gem 'redcarpet', '3.3.4' # Process markdown in form textareas (justifications)
gem 'octokit', '4.1.1' # GitHub's official Ruby API
gem 'omniauth-github', '1.1.2' # Authentication to GitHub (get project info)
gem 'paper_trail', '4.1.0' # Record previous versions of project data
gem 'puma', '3.0.2' # Faster webserver; recommended by Heroku
gem 'rack-timeout', '0.3.2' # Timeout per https://github.com/heroku/rack-timeout
gem 'rails', '4.2.5.2' # Our web framework
gem 'sass-rails', '5.0.4'
gem 'secure_headers', '3.0.3' # Harden app security using HTTP headers
gem 'turbolinks', '2.5.3' # Speed UI access
gem 'jquery-turbolinks'   # Make turbolinks work with jQuery
gem 'uglifier', '2.7.2'
gem 'will_paginate', '3.1.0'

group :development, :test do
  gem 'awesome_print', '1.6.1'
  gem 'bullet', '5.0.0'
  gem 'bundler-audit'
  gem 'ruby-graphviz'
  gem 'dotenv-rails', '2.1.0'
  gem 'license_finder'
  gem 'mdl', '0.2.1'
  gem 'pronto', '0.5.3'
  gem 'pronto-brakeman', '0.5.0'
  gem 'pronto-rails_best_practices', '0.5.1'
  gem 'pronto-rubocop', '0.5.3'
  gem 'pry-byebug', '3.3.0'
  gem 'quiet_assets', '1.1.0'
  gem 'rubocop-rspec', '1.4.0'
  gem 'spring', '1.6.4'
  gem 'sqlite3', '1.3.11'
  gem 'vcr', '3.0.1' # Record network responses for later test reuse
  gem 'yaml-lint', '0.0.7' # Check YAML file syntax
end

group :development do
  gem 'rails_db', '1.1.1' # Enable localhost:3000/rails/db debugging
  gem 'web-console', '3.1.1'
end

group :test do
  gem 'coveralls', '0.8.13', require: false
  gem 'm', '1.4.2' # Run test/unit tests by line number
  gem 'simplecov', '0.11.2', require: false
  gem 'webmock'
end

group :production do
  gem 'pg', '0.18.4' # PostgreSQL database
  gem 'rails_12factor', '0.0.3'
  gem 'heroku_rails_deflate', '1.0.3' # Compress (reduces network load)
end
