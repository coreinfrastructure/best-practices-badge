# frozen_string_literal: true

# This lists all gems we directly depend on.
# We depend on explicit version numbers (so we can control upgrade times).
# Any one gem is listed no more than once (to prevent referring to
# different version numbers in different environments).

source 'https://rubygems.org'

# Use current ruby version (as stated in .ruby-version file)
# https://stackoverflow.com/questions/32934651/is-it-a-bad-practice-to-list-ruby-version-in-both-gemfile-and-ruby-version-dotf
ruby File.read('.ruby-version').strip

# The action* gems are Rails portions. When you upgrade their versions, be
# sure to upgrade them in sync, *including* railties.
# Loading only what we use reduces memory use & attack surface.
# gem 'actioncable' # Not used. Client/server comm channel.
gem 'actionmailer', '5.2.4.4' # Rails. Send email.
gem 'actionpack', '5.2.4.4' # Rails. MVC framework.
gem 'actionview', '5.2.4.4' # Rails. View.
gem 'activejob', '5.2.4.4' # Rails. Async jobs.
gem 'activemodel', '5.2.4.4' # Rails. Model basics.
gem 'activerecord', '5.2.4.4' # Rails. ORM and query system.
# gem 'activestorage' # Not used. Attaches cloud files to ActiveRecord.
gem 'activesupport', '5.2.4.4' # Rails. Underlying library.
# gem 'activetext' # Not used. Text editor that fails to support markdown.
gem 'attr_encrypted', '3.1.0' # Encrypt email addresses
gem 'bcrypt', '3.1.16' # Security - for salted hashed interated passwords
gem 'blind_index', '0.3.4' # Index encrypted email addresses
gem 'bootstrap-sass', '3.4.1'
gem 'bootstrap-social-rails', '4.12.0'
gem 'bootstrap_form', '2.7.0'
gem 'bundler' # Ensure it's available
gem 'chartkick', '3.4.0' # Chart project_stats
# We no longger use "fastly-rails"; it doesn't support Rails 6+.
# They recommend switching to the "fastly" gem (aka "fastly-ruby"),
# but fastly-ruby is not designed to support multi-threading, so we
# call the Fastly API directly instead.
gem 'font-awesome-rails', '4.7.0.5'
gem 'http_accept_language', '2.1.1' # Determine user's preferred locale
gem 'httparty', '0.18.1' # HTTP convenience. rake fix_use_gravatar
gem 'imagesLoaded_rails', '4.1.0' # JavaScript - enable wait for image load
gem 'jbuilder', '2.11.1' # Template mechanism for JSON format results
gem 'jquery-rails', '4.4.0' # JavaScript jQuery library (for Rails)
gem 'jquery-ui-rails', '6.0.1' # JavaScript jQueryUI library (for Rails)
gem 'lograge', '0.11.2' # Simplify logs
gem 'mail', '2.7.1' # Ruby mail handler
#
gem 'octokit', '4.18.0' # GitHub's official Ruby API
gem 'omniauth-github', '1.4.0' # Authentication to GitHub (get project info)
#
# Counter CVE-2015-9284 in omniauth.  Unfortunately, at the time of this
# writing the omniauth folks STILL have not fixed it (!). There is a shim
# by a third party that *does* fix it. I don't know the person who created
# this shim, but I reviewed the code and it looks okay.
# At one time I did this:
# gem 'omniauth-rails_csrf_protection',
#    git: 'https://github.com/cookpad/omniauth-rails_csrf_protection.git',
#    ref: 'b33ff2e57f7c0530da76da6b4b358218f1e7f230'
# to provide a stronger guarantee that what I reviewed is what will
# be loaded, by specifying a specific hash reference.
# However, using a git reference busts CI pipeline caching, slowing down
# all testing, and over time we've become more comfortable that this is
# the "standard way to resolve this issue".
gem 'omniauth-rails_csrf_protection', '0.1.2' # Counter CVE-2015-9284
gem 'pagy', '3.10.0' # Paginate some views
gem 'paleta', '0.3.0' # Color manipulation, used for badges
gem 'paper_trail', '10.3.1' # Record previous versions of project data
gem 'pg', '1.2.3' # PostgreSQL database, used for data storage
gem 'pg_search', '2.3.5' # PostgreSQL full-text search
gem 'puma', '4.3.6' # Faster webserver; recommended by Heroku
gem 'puma_worker_killer', '0.3.1' # Band-aid: Restart to limit memory use
gem 'rack-attack', '6.3.1' # Implement rate limiting
gem 'rack-cors', '1.1.1' # Enable CORS so JavaScript clients can get JSON
gem 'rack-headers_filter', '0.0.1' # Filter out "dangerous" headers
# We no longer say: gem 'rails', '5.2.4.4' # Our web framework
# but instead load only what we use (to reduce memory use and attack surface).
# We load sprockets-rails, but its version number isn't kept in sync.
# Note: Update the gem versions of action* and railties in sync.
gem 'railties', '5.2.4.4' # Rails. Rails core, loads rest of Rails
gem 'rails-i18n', '5.1.3' # Localizations for Rails built-ins
gem 'redcarpet', '3.5.1' # Process markdown in form textareas (justifications)
gem 'sass-rails', '5.1.0', require: false # For .scss files (CSS extension)
gem 'scout_apm', '2.6.9' # Monitor for memory leaks
gem 'secure_headers', '6.3.1' # Add hardening measures to HTTP headers
gem 'sprockets-rails', '3.2.2' # Rails. Asset precompilation
gem 'uglifier', '4.2.0', require: false # Minify JavaScript

group :development, :test do
  gem 'awesome_print', '1.8.0' # Pretty print Ruby objects
  gem 'bullet', '6.1.3' # Avoid n+1 queries
  gem 'bundler-audit', '0.7.0.1'
  gem 'database_cleaner', '1.8.5' # Cleans up database between tests
  gem 'dotenv-rails', '2.7.6'
  gem 'eslintrb', '2.1.0'
  gem 'json', '2.3.1'
  gem 'license_finder', '6.0.0'
  gem 'mdl', '0.10.0'
  gem 'pronto', '0.10.0'
  # TODO: Use pronto-railroader, once there is one.
  # gem 'pronto-brakeman', '0.9.1'
  gem 'pronto-eslint', '0.10.0'
  gem 'pronto-rails_best_practices', '0.10.0'
  gem 'pronto-rubocop', '0.10.0'
  # gem 'railroader', '4.3.8' # Security static analyzer. OSS fork of Brakeman
  gem 'rubocop', '0.91.1', require: false # Style checker
  gem 'rubocop-performance', '1.8.0', require: false # Performance cops
  gem 'rubocop-rails', '2.8.0', require: false # Rails-specific cops
  gem 'ruby-graphviz', '1.2.5' # This is used for bundle viz
  gem 'spring', '2.1.1' # Preloads app so console, rake, and tests run faster
  # Do NOT upgrade to vcr 6.*, as that is not OSS:
  gem 'vcr', '5.0.0' # Record network responses for later test reuse
  gem 'yaml-lint', '0.0.10' # Check YAML file syntax
end

# The "fake_production" environment is very much like production, however,
# we enable a few debug tools to help us find "production-only" bugs.
group :fake_production, :development, :test do
  gem 'pry-byebug', '3.9.0'
end

group :development do
  gem 'bootsnap', '1.4.8' # Speed up boot via caches
  # gem 'fasterer', '0.3.2' # Provide speed recommendations - run 'fasterer'
  # Waiting for Ruby 2.4 support: https://github.com/seattlerb/ruby_parser/issues/239
  gem 'traceroute', '0.8.1' # Adds 'rake traceroute' command to check routes
  gem 'translation', '1.22' # translation.io - translation service
  gem 'web-console', '3.7.0' # Debugging tool for Ruby on Rails apps
end

group :test do
  gem 'capybara-selenium', '0.0.6', require: false
  gem 'capybara-slow_finder_errors', '0.1.5', require: false
  gem 'codecov', '0.3.0', require: false
  # Note: We should eventually remove minitest-rails-capybara, and
  # switch completely over to using Rails System Tests instead. Statement:
  # "minitest-rails-capybara support ends with minitest-rails 3.x.  If you
  # want to use minitest-rails 5.1+ you should transition to system tests."
  # https://github.com/blowmage/minitest-rails-capybara/issues/44
  # https://blowmage.com/2019/06/18/minitest-rails-releases
  # https://guides.rubyonrails.org/testing.html
  gem 'minitest-rails-capybara', '3.0.2', require: false
  gem 'minitest-reporters', '1.4.3', require: false
  gem 'minitest-retry', '0.2.1', require: false # Avoid Capybara false positives
  # Note: Updating 'rails-controller-testing' to '1.0.5' causes failures
  gem 'rails-controller-testing', '1.0.4' # for `assigns` and `assert_template`
  gem 'selenium-webdriver', '3.142.7', require: false
  # We don't list "simplecov"; code depends on it & brings it in
  gem 'webdrivers', '4.5.0', require: false
  gem 'webmock', '3.9.4', require: false
end

group :production do
  gem 'rack-timeout', '0.6.0' # Timeout; https://github.com/heroku/rack-timeout
  gem 'rails_12factor', '0.0.3'
end

# Post-install message from autoprefixer-rails:
# autoprefixer-rails was deprected. Migration guide:
# https://github.com/ai/autoprefixer-rails/wiki/Deprecated
