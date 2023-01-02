# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in
  # config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store =
    :memory_store,
    { size: (ENV['RAILS_CACHE_SIZE'] || '128').to_i.megabytes }

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  # config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # We want to serve compressed values
  config.assets.compress = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not allow "live compilation" using the assets pipeline
  # if a precompiled asset is unavailable.  Instead, assets must be precompiled
  # for the production environment.
  # The Rails guide for the asset pipeline at
  # https://guides.rubyonrails.org/asset_pipeline.html
  # says that live compilation "uses more memory, performs more poorly
  # than the default and is not recommended".
  # Disabling live compilation is also recommended by Heroku's documentation
  # at: https://devcenter.heroku.com/articles/rails-asset-pipeline#
  # compile-set-to-true-in-production
  # which says: "If you have enabled your application to config.assets.compile =
  # true in production, your application might be very slow...
  # This setting is also known to cause other run-time instabilities and is
  # generally not recommended. Instead we recommend either precompiling all
  # of your assets on deploy (which is the default)..."
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all
  # assets, yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to
  # config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use
  # secure cookies.
  config.force_ssl = true unless ENV['DISABLE_FORCE_SSL']

  # Use the :info log level by default, not the lowest (:debug);
  # the site is now busy enough that ":debug" floods the logs.
  # You can override this using RAILS_LOG_LEVEL
  config.log_level = (ENV['RAILS_LOG_LEVEL'] || :info).to_sym

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Figure out public hostname
  host = (ENV['PUBLIC_HOSTNAME'] || 'public-hostname-not-configured')

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'
  # Set asset_host to help counter host header injection; see
  # https://github.com/ankane/secure_rails
  config.action_controller.asset_host = host

  # Configure email server.
  # For discussion about how to do this, see:
  # https://www.railstutorial.org/book/account_activation_password_reset
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: host }
  ActionMailer::Base.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: '587',
    authentication: :plain,
    user_name: ENV.fetch('SENDGRID_USERNAME', nil),
    password: ENV.fetch('SENDGRID_PASSWORD', nil),
    domain: 'heroku.com',
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  # This is now handled by "initializers/i18n.rb"; see that file.
  # config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Use Fastly as a CDN. See: https://devcenter.heroku.com/articles/fastly
  # config.action_controller.asset_host = ENV['FASTLY_CDN_URL']
  # Use CDN directly for static assets
  # TODO: Do we need to set this to true?
  # The documentation for Fastly suggests setting
  # "config.serve_static_assets = true".  However, this has since been
  # renamed to "config.serve_static_files", which we already conditionally set.

  # Cache static content.  Cache for a long time; the asset cache is
  config.public_file_server.headers =
    {
      'Cache-Control' =>
        'public, s-maxage=31536000, max-age=31536000, immutable'
    }

  # Enable Rack's built-in compression mechanism; this is important for people
  # with slow network connections
  config.middleware.use Rack::Deflater

  # First thing, filter out bad HTTP headers (0 == first)
  # By default this accepts the HTTP headers set by Heroku (and thus trusted),
  # but otherwise removes some "dangerous" headers.  In particular, it
  # removes the X-Forwarded-Host HTTP header, which in Rails is
  # inexplicably trusted and is used in url_for, even though it comes
  # from an untrusted user. See:
  # https://github.com/rails/rails/issues/29893
  # https://github.com/ankane/secure_rails
  # http://carlos.bueno.org/2008/06/host-header-injection.html
  # We generally want to implement whitelists, not blacklists, but
  # this is an easy way to make sure that certain dangerous headers
  # cannot be unintentionally used in the first place.
  config.middleware.insert_before(0, Rack::HeadersFilter)

  # In production and fake_production environments turn on "lograge".
  # This makes the logs easier to read and removes cruft that, while useful
  # in development, can be overwhelming in production.
  config.lograge.enabled = true

  # Report user_id in logs
  # https://github.com/roidrage/lograge/issues/23
  config.lograge.custom_options =
    lambda do |event|
      uid = event.payload[:uid]
      if uid
        { uid: uid }
      else
        {}
      end
    end

  # The timeout used by Rack::Timeout is not set here (any more);
  # it is set via the environment variable RACK_TIMEOUT_SERVICE_TIMEOUT.
  # For more on controlling timeout-related times, see:
  # https://github.com/sharpstone/rack-timeout
  #
  # As a failsafe, we trigger an exception if the response just hangs for
  # too long.  We only do this in production, because it's not
  # supposed to happen in normal use - this is simply an automatic
  # recovery mechanism if things get stuck.  We don't do this in test or
  # development, because it interferes with their purposes.
  # This call will fail in fake_production, so we ignore the exception.
  # rubocop:disable Lint/HandleExceptions
  begin
    # Unfortunately Rack::Timeout doesn't provide a lot of control over logging.
    # What it provides (now) is described here:
    # https://github.com/sharpstone/rack-timeout/blob/master/doc/logging.md
    # The timeout reports are really noisy, and don't seem to help debug
    # typical problems (if anything they get in the way).  Disable them.
    Rack::Timeout::Logger.disable
  rescue NameError
    # Do nothing if it's unavailable (this happens if we didn't load the gem)
  end
  # rubocop:enable Lint/HandleExceptions
end
# rubocop:enable Metrics/BlockLength
