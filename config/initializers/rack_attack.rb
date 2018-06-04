# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT
# However, much of this is instead from:
# https://github.com/kickstarter/rack-attack/wiki/Example-Configuration

# NOTE: This may need additional work to get the "real" client IP from Heroku
# instead of the routing IP inside req.ip.

# Use recommended format of Rack::Attack config
# rubocop: disable Style/ClassAndModuleChildren, Style/SymbolProc
# rubocop: disable Style/IfUnlessModifier, Style/MethodCalledOnDoEndBlock
class Rack::Attack
  # Configure Rack::Attack to do rate limiting.

  # Create a set of possible login paths
  # "i18n" comes before "rack_attack" alphabetically, so
  # I18n.available_locales is configured by this point.
  LOGIN_PATHS = I18n.available_locales.map do |loc|
    "/#{loc}/login"
  end.append('/login').to_set

  SIGNUP_PATHS = I18n.available_locales.map do |loc|
    "/#{loc}/users"
  end.append('/users').to_set

  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blacklisting and
  # whitelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Safelists ###

  # Always allow requests from localhost if testing.
  # (blocklist & throttles are skipped)
  # In the future, we may make it so that only by DEFAULT testing is in
  # safelist, and an HTTP header during testing will cause the safelist to
  # skipped, so we can test the rest of the conditions more easily.
  # TODO: We currently EXPRESSLY safelist everything for the real site,
  # so that if this ends up on the main site nothing bad can happen.
  if Rails.env.test? ||
     ENV['PUBLIC_HOSTNAME'] == 'bestpractices.coreinfrastructure.org'
    Rack::Attack.safelist('allow from localhost') do |req|
      # Requests are allowed if the return value is truthy
      req.ip == '127.0.0.1' || req.ip == '::1'
    end
  end

  Rack::Attack.safelist('debug') do |req|
    # Requests are allowed if the return value is truthy
    if req.path == '/debug' || req.path == '/en/debug'
      Rails.logger.error "DEBUG /debug req.ip=<#{req.ip}>, " \
        "HTTP_X_FORWARDED_FOR=<#{req.get_header('HTTP_X_FORWARDED_FOR')}>, " \
        "HTTP_X_REAL_IP=<#{req.get_header('HTTP_X_REAL_IP')}>, " \
        "REMOTE_ADDR=<#{req.get_header('REMOTE_ADDR')}>"
    end
    nil
  end

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /login by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if LOGIN_PATHS.include?(req.path) && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /login by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{req.email}"
  #
  # Note: This creates a problem where a malicious user could intentionally
  # throttle logins for another user and force their login requests to be
  # denied, but that's not very common and shouldn't happen to you. (Knock
  # on wood!)
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if LOGIN_PATHS.include?(req.path) && req.post? && req.params['session']
      # return the email to throttle logins on if present, nil otherwise
      req.params['session']['email']
    end
  end

  ### Throttle local signup to /users by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:signup/ip:#{req.ip}"
  #
  # Limit the number of times an IP address can try to sign up for a local
  # account in a short period of time.  Normal users have no reason to
  # try to create that many different accounts.  We don't need to limit
  # by email address; once an email address has been signed up, it
  # stays that way.
  #
  throttle('signup/ip', limit: 5, period: 5.minutes) do |req|
    if SIGNUP_PATHS.include?(req.path) && req.post?
      req.ip
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_response = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end
end
# rubocop: enable Style/IfUnlessModifier, Style/MethodCalledOnDoEndBlock
# rubocop: enable Style/ClassAndModuleChildren, Style/SymbolProc
