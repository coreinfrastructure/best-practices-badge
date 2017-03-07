# frozen_string_literal: true
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
  config.cache_store = :memory_store, { size: 64.megabytes }

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
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Asset digests allow you to set far-future HTTP expiration dates on all
  # assets, # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to
  # config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use
  # secure cookies.
  config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Configure email server.
  # For discussion about how to do this, see:
  # https://www.railstutorial.org/book/account_activation_password_reset
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  host = (ENV['PUBLIC_HOSTNAME'] || 'public-hostname-not-configured')
  config.action_mailer.default_url_options = { host: host }
  ActionMailer::Base.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: '587',
    authentication: :plain,
    user_name: ENV['SENDGRID_USERNAME'],
    password: ENV['SENDGRID_PASSWORD'],
    domain: 'heroku.com',
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Use Fastly as a CDN. See: https://devcenter.heroku.com/articles/fastly
  # config.action_controller.asset_host = ENV['FASTLY_CDN_URL']
  # Use CDN directly for static assets
  # TODO: Do we need to set this to true?
  # The documentation for Fastly suggests setting
  # "config.serve_static_assets = true".  However, this has since been
  # renamed to "config.serve_static_files", which we already conditionally set.
  # Cache static content.  Until we're confident in the results, we'll
  # use a relatively short caching time of 1 hour.
  # config.static_cache_control = 'public, s-maxage=2592000, maxage=86400'
  # config.static_cache_control = 'public, s-maxage=3600, maxage=3600'
  config.public_file_server.headers =
    {
      'Cache-Control' => 'public, s-maxage=3600, max-age=3600'
    }

  # Enable Rack's built-in compression mechanism; this is important for people
  # with slow network connections
  config.middleware.use Rack::Deflater

  # As a failsafe, trigger an exception if the response just hangs for
  # too long.  We only do this in production, because it's not
  # supposed to happen in normal use - this is simply an automatic
  # recovery mechanism if things get stuck.  We don't do this in test or
  # development, because it interferes with their purposes.
  # The "use" form is preferred, but it doesn't actually work when placed
  # in this file, so we'll just set the timeout directly.
  Rack::Timeout.service_timeout = 30 # seconds
end
# rubocop:enable Metrics/BlockLength
