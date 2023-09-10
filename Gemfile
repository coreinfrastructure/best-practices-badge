# frozen_string_literal: true

# This lists all gems we directly depend on.
# We depend on explicit version numbers (so we can control upgrade times).
# Any one gem is listed no more than once (to prevent referring to
# different version numbers in different environments).

# Updating Rails-related gems requires simultaneously updating them.
# You may need to update all of their versions below. Then run this:
# bundle update actionmailer actionpack actionview activejob activemodel \
#        activerecord activesupport railties rails-i18n rails

source 'https://rubygems.org'

# Use current ruby version (as stated in .ruby-version file)
# https://stackoverflow.com/questions/32934651/is-it-a-bad-practice-to-list-ruby-version-in-both-gemfile-and-ruby-version-dotf
ruby File.read('.ruby-version').strip

# The action* gems are Rails portions. When you upgrade their versions, be
# sure to upgrade them in sync, *including* railties.
# Loading only what we use reduces memory use & attack surface.
# gem 'actioncable' # Not used. Client/server comm channel.
# gem 'activestorage' # Not used. Attaches cloud files to ActiveRecord.
gem 'actionmailer', '~> 7.0.7' # Rails. Send email.
gem 'actionpack', '~> 7.0.7' # Rails. MVC framework.
gem 'actionview', '~> 7.0.7' # Rails. View.
gem 'activejob', '~> 7.0.7' # Rails. Async jobs.
gem 'activemodel', '~> 7.0.7' # Rails. Model basics.
gem 'activerecord', '~> 7.0.7' # Rails. ORM and query system.
# gem 'activestorage' # Not used. Attaches cloud files to ActiveRecord.
gem 'activesupport', '~> 7.0.7' # Rails. Underlying library.
# gem 'activetext' # Not used. Text editor that fails to support markdown.
gem 'attr_encrypted', '~> 4'
gem 'bcrypt', '~> 3.1.18' # Security - for salted hashed interacted passwords
gem 'blind_index', '~> 2.3.0' # Index encrypted email addresses
gem 'bootstrap-sass', '~> 3.4'
gem 'bootstrap-social-rails', '~> 4.12'
gem 'bootstrap_form', '~> 2.7'
gem 'bundler' # Ensure it's available
# Note: if webpacker is used, see chartkick website for added instructions
gem 'chartkick', '~> 4.0' # Chart project_stats
gem 'faraday-retry', '~> 2.1' # Force retry of faraday requests for reliability
# We no longger use "fastly-rails"; it doesn't support Rails 6+.
# They recommend switching to the "fastly" gem (aka "fastly-ruby"),
# but fastly-ruby is not designed to support multi-threading, so we
# call the Fastly API directly instead.
gem 'font-awesome-rails', '~> 4.7'
gem 'http_accept_language', '~> 2.1' # Determine user's preferred locale
gem 'httparty' # HTTP convenience. rake fix_use_gravatar
gem 'imagesLoaded_rails', '~> 4.1' # JavaScript - enable wait for image load
gem 'jbuilder', '~> 2.11' # Template mechanism for JSON format results
gem 'jquery-rails', '~> 4.4' # JavaScript jQuery library (for Rails)
gem 'jquery-ui-rails', '~> 6.0' # JavaScript jQueryUI library (for Rails)
gem 'lograge', '~> 0.12' # Simplify logs
gem 'mail', '~> 2.7' # Ruby mail handler
#
gem 'octokit', '~> 6.1' # GitHub's official Ruby API
gem 'omniauth-github', '~> 2.0' # Authentication to GitHub (get project info)
#
# Counter CVE-2015-9284 in the omniauth 1.X series.
# The omniauth gem 1.X series has a vulnerability if GET requests are used
# for login, and it was left unfixed for years. A countermeasure is using POST.
# For a discussion on this countermeasure see:
# <https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284>.
# We are *not* vulnerable, because we use the POST method for /auth; see:
# app/views/sessions/new.html.erb
# For added protection we also use a
# writing the omniauth folks STILL have not fixed it (!). There is a shim
# a third party that *does* fix it. I don't know the person who created
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
# When we update to omniauth 2.X series we can remove this.
gem 'omniauth-rails_csrf_protection'
gem 'pagy', '~> 6.0'
gem 'paleta', '~> 0.3' # Color manipulation, used for badges
gem 'paper_trail', '~> 12.3' # Record previous versions of project data
gem 'pg', '~> 1.4' # PostgreSQL database, used for data storage
gem 'pg_search', '~> 2.3' # PostgreSQL full-text search
gem 'puma', '~> 6.3' # Faster webserver; recommended by Heroku
gem 'puma_worker_killer', '~> 0.3' # Band-aid: Restart to limit memory use
gem 'rack-attack', '~> 6.7' # Implement rate limiting
gem 'rack-cors', '~> 2.0' # Enable CORS so JavaScript clients can get JSON
gem 'rack-headers_filter', '~> 0.0.1' # Filter out "dangerous" headers
# We no longer say: gem 'rails', '6.1.7.3' # Our web framework
# but instead load only what we use (to reduce memory use and attack surface).
# We load sprockets-rails, but its version number isn't kept in sync.
# Note: Update the gem versions of action* and railties in sync.
gem 'railties', '~> 7.0.7' # Rails. Rails core, loads rest of Rails
gem 'rails-i18n', '~> 7.0.7' # Localizations for Rails built-ins
gem 'redcarpet', '~> 3.5' # Process markdown in form textareas (justifications)
gem 'sass-rails', '~> 5.1', require: false # For .scss files (CSS extension)
gem 'scout_apm' # Monitor for memory leaks
gem 'secure_headers', '~> 6.3' # Add hardening measures to HTTP headers
# WARNING!!!!
# CHECK DEPLOYMENT FIRST IF YOU UPDATE sprockets-rails.
# The gem sprockets-rails version 3.4.1 (from 3.2.2) caused a regression
# in deployment (icons no longer displayed) that does NOT occur locally.
# WARNING!!!!
gem 'sprockets-rails', '3.4.2' # Rails. Asset precompilation
gem 'uglifier', '~> 4.2.0', require: false # Minify JavaScript
gem 'sentry-ruby'
gem 'sentry-rails'

group :development, :test do
  gem 'awesome_print' # Pretty print Ruby objects
  gem 'bullet' # Avoid n+1 queries
  gem 'bundler-audit'
  gem 'dotenv-rails', '~> 2.7'
  gem 'eslintrb'
  gem 'json', '~> 2.0'
  gem 'license_finder', '~> 7.0'
  gem 'mdl', '0.12.0'
  # NOTE: If you update pronto you may need to update other pronto-* gems
  gem 'pronto', '0.11.1'
  # TODO: Use pronto-railroader, once there is one.
  # gem 'pronto-brakeman', '0.9.1'
  gem 'pronto-eslint', '0.11.1'
  gem 'pronto-rails_best_practices', '0.11.0'
  gem 'pronto-rubocop', '0.11.5'
  # gem 'railroader', '4.3.8' # Security static analyzer. OSS fork of Brakeman
  gem 'rubocop', '1.50.1', require: false # Style checker
  gem 'rubocop-performance', '1.17.1', require: false # Performance cops
  gem 'rubocop-rails', '2.19.0', require: false # Rails-specific cops
  gem 'ruby-graphviz', '1.2.5' # This is used for bundle viz
  gem 'spring', '~> 4.1'
  # Do NOT upgrade to vcr 6.*, as that is not OSS:
  gem 'vcr', '< 5.1' # Record network responses for later test reuse
  gem 'yaml-lint', '~> 0.1.2' # Check YAML file syntax
end

# The "fake_production" environment is very much like production, however,
# we enable a few debug tools to help us find "production-only" bugs.
group :fake_production, :development, :test do
  gem 'pry-byebug'
end

group :development do
  gem 'bootsnap' # Speed up boot via caches
  # gem 'fasterer', '0.3.2' # Provide speed recommendations - run 'fasterer'
  # Waiting for Ruby 2.4 support:
  # https://github.com/seattlerb/ruby_parser/issues/239
  # gem 'traceroute', '0.8.1' # Adds 'rake traceroute' command to check routes
  # We bring in full rails in development in case we need it for debugging;
  # this also keeps some gems happy that don't realize that loading
  # only *parts* of Rails is fine:
  gem 'rails', '~> 7.0.7' # Rails (our web framework)
  # To update the translation gem, see the process docs in doc/testing.md
  gem 'translation', '1.37' # translation.io - translation service
  gem 'web-console' # In-browser debugger; use <% console %> or console
end

group :test do
  gem 'capybara-slow_finder_errors', require: false
  gem 'codecov', require: false
  gem 'minitest-reporters', require: false
  gem 'minitest-retry', require: false # Avoid Capybara false positives
  # Note: Updating 'rails-controller-testing' to '1.0.5' causes failures
  gem 'rails-controller-testing', '~> 1.0' # for `assigns` and `assert_template`
  gem 'selenium-webdriver'
  # We don't list "simplecov"; code depends on it & brings it in
  gem 'webdrivers'
  gem 'webmock', '~> 3.0', require: false
end

group :production do
  gem 'rack-timeout', '~> 0.6.3' # Timeout; https://github.com/heroku/rack-timeout
  gem 'rails_12factor', '~> 0.0.3'
end

# Post-install message from autoprefixer-rails:
# autoprefixer-rails was deprecated. Migration guide:
# https://github.com/ai/autoprefixer-rails/wiki/Deprecated
