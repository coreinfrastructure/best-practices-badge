# frozen_string_literal: true

if (dsn = ENV.fetch('SENTRY_DSN', nil))
  Sentry.init do |config|
    config.dsn = dsn
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
  end
end
