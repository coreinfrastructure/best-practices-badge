# frozen_string_literal: true

require File.expand_path('../production', __FILE__)

Rails.application.configure do
  config.force_ssl = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :test
  host = 'localhost:3000'
  config.action_mailer.default_url_options = { host: host }
end
