# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in
  # config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers =
    { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true
  config.cache_store =
    :memory_store,
    { size: (ENV['RAILS_CACHE_SIZE'] || '128').to_i.megabytes }

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Raise exceptions during test if a translation is missing
  config.i18n.raise_on_missing_translations = true

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  host = 'localhost:3000'
  config.action_mailer.default_url_options = { host: host }

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Enable Rack's built-in compression mechanism; this is important for people
  # with slow network connections.  Enable during tests to make test
  # more like production
  config.middleware.use Rack::Deflater

  config.after_initialize do
    # The 'bullet' gem watches application queries and notifies
    # when you should add eager loading (N+1 queries),
    # when you're using eager loading that isn't necessary and
    # when you should use counter cache.
    Bullet.enable = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
    Bullet.raise = true # raise an error if n+1 query occurs
    # Bullet.alert = true
    # Bullet.bullet_logger = true
    # Bullet.console = true
    # Bullet.growl = true
    # Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
    #               :password => 'bullets_password_for_jabber',
    #               :receiver => 'your_account@jabber.org',
    #               :show_online_status => true }
    # Bullet.honeybadger = true
    # Bullet.bugsnag = true
    # Bullet.airbrake = true
    # Bullet.rollbar = true
    # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
    # Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware' ]
    # Bullet.slack = { webhook_url: 'http://some.slack.url', foo: 'bar' }
  end
end
# rubocop:enable Metrics/BlockLength
