# frozen_string_literal: true
# See https://github.com/fastly/fastly-rails

if !ENV['FASTLY_API_KEY'] && !Rails.env.testing?
  Rails.logger.warn 'FASTLY_API_KEY is not set.'
end

FastlyRails.configure do |c|
  c.api_key = ENV['FASTLY_API_KEY'] # Fastly api key, required
  c.max_age = 86_400 # time in seconds, optional, default 2592000 (30 days)
  c.service_id = ENV['FASTLY_SERVICE_ID'] # The Fastly service, required
  c.purging_enabled = !Rails.env.development? && !Rails.env.testing? &&
                      ENV['FASTLY_API_KEY']
end
