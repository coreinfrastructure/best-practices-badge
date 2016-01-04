source 'https://rubygems.org'
ruby '2.3.0'

gem 'autosize-rails', '1.18.17' # Improve HTML textareas
gem 'bcrypt', '3.1.10' # Security - for salted hashed interated passwords
gem 'bootstrap-sass', '3.3.6'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'bootstrap_form', '2.3.0'
gem 'faker', '1.6.1'
gem 'github_api', '0.13.0'
gem 'jbuilder', '2.3.2'
gem 'jquery-rails', '4.0.5' # Javascript jQuery library (for Rails)
gem 'jquery-ui-rails', '5.0.5' # Javascript jQueryUI library (for Rails)
gem 'octokit', '4.1.1' # GitHub's official Ruby API
gem 'omniauth-github', '1.1.2' # Authentication to GitHub (get project info)
gem 'paper_trail', '4.0.1' # Record previous versions of project data
gem 'puma', '2.15.3' # Faster webserver; recommended by Heroku
gem 'rack-timeout', '0.3.2' # Timeout per https://github.com/heroku/rack-timeout
gem 'rails', '4.2.5' # Our web framework
gem 'sass-rails', '5.0.4'
gem 'turbolinks', '2.5.3' # Speed UI access
gem 'jquery-turbolinks'   # Make turbolinks work with jQuery
gem 'uglifier', '2.7.2'
gem 'will_paginate', '3.0.7'

group :development, :test do
  gem 'awesome_print', '1.6.1'
  gem 'bullet', '4.14.10'
  gem 'bundler-audit'
  gem 'dotenv-rails', '2.0.2'
  gem 'license_finder'
  gem 'mdl', '0.2.1'
  gem 'pronto', '0.5.3'
  gem 'pronto-brakeman', '0.5.0'
  gem 'pronto-rails_best_practices', '0.5.0'
  gem 'pronto-rubocop', '0.5.0'
  gem 'pry-byebug', '3.3.0'
  gem 'quiet_assets', '1.1.0'
  gem 'rubocop-rspec', '1.3.1'
  gem 'spring', '1.6.1'
  gem 'sqlite3', '1.3.11'
  gem 'vcr', '3.0.1' # Record network responses for later test reuse
end

group :development do
  gem 'rails_db', '1.0.0' # Enable localhost:3000/rails/db debugging
  gem 'web-console', '3.0.0'
end

group :test do
  gem 'coveralls', '0.8.10', require: false
  gem 'm', '1.4.2' # Run test/unit tests by line number
  gem 'simplecov', '0.11.1', require: false
  gem 'webmock'
end

group :production do
  gem 'pg', '0.18.4' # PostgreSQL database
  gem 'rails_12factor', '0.0.3'
end
