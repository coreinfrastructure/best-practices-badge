# frozen_string_literal: true

require 'active_support'

# if (dsn = ENV.fetch('SENTRY_DSN', nil))
# Sentry.init do |config|
# config.dsn = dsn
# config.breadcrumbs_logger = %i[active_support_logger http_logger]

# filter = ActiveSupport::ParameterFilter.new([:name, :email, :password, :password_digest, :secret_token])
# config.before_send =
# lambda do |event, _hint|
# filter.filter(event.to_hash)
# end
# end
# end
Sentry.init do |config|
  config.dsn = 'https://5d36d0916305be3ae53900478410fbf4@o4505909465317376.ingest.sentry.io/4505909471674368'
  filter = ActiveSupport::ParameterFilter.new(%i[name email password password_digest secret_token])
  config.before_send =
    lambda do |event, _hint|
      filter.filter(event.to_hash)
    end
end
