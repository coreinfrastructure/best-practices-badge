# frozen_string_literal: true

# See https://github.com/fastly/fastly-rails

require 'net/https'
require 'json'
require 'ipaddr'

# Download list of valid IP addresses from this (be SURE this is https!):
iplist_uri = 'https://api.fastly.com/public-ip-list'

# Ensure that there's *a* value for valid_client_ips (nil=all allowed)
Rails.configuration.valid_client_ips = nil

if !ENV['FASTLY_API_KEY'] && !Rails.env.testing?
  Rails.logger.warn 'FASTLY_API_KEY is not set.'
end

FastlyRails.configure do |c|
  c.api_key = ENV['FASTLY_API_KEY'] # Fastly api key, required for it to work
  c.max_age = 86_400 # time in seconds, optional, default 2592000 (30 days)
  c.service_id = ENV['FASTLY_SERVICE_ID'] # The Fastly service, required
  c.purging_enabled = !Rails.env.development? && !Rails.env.testing? &&
                      ENV['FASTLY_API_KEY']
end

if ENV['FASTLY_CLIENT_IP_REQUIRED']
  # Set up list of valid IP addresses, assumes iplist_uri is accessible.
  # Note: Ruby's HTTP.get *does* check for invalid certs, e.g., it
  # will error out if given 'https://wrong.host.badssl.com/' (*yay*).
  Rails.logger.info 'Getting Fastly public IPs'
  iplist_text = Net::HTTP.get(URI(iplist_uri))
  iplist_json = JSON.parse(iplist_text)
  iplist_ips = iplist_json['addresses'].map { |i| IPAddr.new(i) }
  Rails.configuration.valid_client_ips = iplist_ips
end
