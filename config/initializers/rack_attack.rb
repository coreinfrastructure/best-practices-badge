# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT
# However, much of this is instead from:
# https://github.com/kickstarter/rack-attack/wiki/Example-Configuration

# This assumes that "ClientIp.acquire" works correctly.

# Use recommended format of Rack::Attack config
# rubocop: disable Style/ClassAndModuleChildren
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

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.
  # In the case of the BadgeApp, assets are NOT being served via rack.

  # Throttle all requests by IP (120rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  unless Rails.env.test?
    throttle(
      'req/ip',
      limit: (ENV['RATE_REQ_IP_LIMIT'] || 600).to_i,
      period: (ENV['RATE_REQ_IP_PERIOD'] || 5.minutes).to_i
    ) do |req|
      ClientIp.acquire(req) # unless req.path.start_with?('/assets')
    end
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
  unless Rails.env.test?
    throttle(
      'logins/ip',
      limit: (ENV['RATE_LOGINS_IP_LIMIT'] || 20).to_i,
      period: (ENV['RATE_LOGINS_IP_PERIOD'] || 20.seconds).to_i
    ) do |req|
      if LOGIN_PATHS.include?(req.path) && req.post?
        ClientIp.acquire(req)
      end
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
  unless Rails.env.test?
    throttle(
      'logins/email',
      limit: (ENV['RATE_LOGINS_EMAIL_LIMIT'] || 5).to_i,
      period: (ENV['RATE_LOGINS_EMAIL_PERIOD'] || 20.seconds).to_i
    ) do |req|
      if LOGIN_PATHS.include?(req.path) && req.post? && req.params['session']
        # return the email to throttle logins on if present, nil otherwise
        req.params['session']['email']
      end
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
  unless Rails.env.test?
    throttle(
      'signup/ip',
      limit: (ENV['RATE_SIGNUP_IP_LIMIT'] || 20).to_i,
      period: (ENV['RATE_SIGNUP_IP_PERIOD'] || 10.seconds).to_i
    ) do |req|
      if SIGNUP_PATHS.include?(req.path) && req.post?
        ClientIp.acquire(req)
      end
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

  ### Block an IP address that is repeatedly making suspicious requests.
  # After FAIL2BAN_MAXRETRY blocked requests in FAIL2BAN_FINDTIME seconds,
  # block all requests from that client IP for FAIL2BAN_BANTIME seconds.
  # A request is blocked if req.path matches the regex FAIL2BAN_PATH or
  # req.query_string matches the regex FAIL2BAN_QUERY.
  FAIL2BAN_MAXRETRY = (ENV['FAIL2BAN_MAXRETRY'] || 3).to_i
  FAIL2BAN_FINDTIME = (ENV['FAIL2BAN_FINDTIME'] || 10.minutes).to_i
  FAIL2BAN_BANTIME = (ENV['FAIL2BAN_BANTIME'] || 20.minutes).to_i
  # Default regexp for paths to disallow.  Coordinate with "robots.txt"
  # so that we don't ban properly-behaving web crawlers, see:
  # https://www.ctrl.blog/entry/httpd-wordpress-deny
  # https://gist.github.com/cerlestes/1d6f1549f06350f7c4f4
  # We don't need to make this locale-specific, because we'll reject
  # these *before* we hit the "redirect to locale" code.
  # Good attackers will make better attacks than these; the point here
  # is to quickly squelch script kiddies with badly-written/old attacks,
  # so we have more time to deal with other things.
  # "/admin" is a common admin URL. "/wp-" handles attacks on WordPress.
  # "/cgi" includes "cgi-bin", a standard prefix for old-school CGI programs.
  # (?:...) is a non-capturing regexp group - we don't need to capture it.
  FAIL2BAN_PATH = Regexp.compile(
    ENV['FAIL2BAN_PATH'] ||
    '^/(?:admin|backup|cgi|command|common|config|' \
    'data|dbadmin|dump|error_message|install|joomla|' \
    'muieblackcat|myadmin|mysql|onvif|options|' \
    'phpadmin|phpmanager|phpmyadmin|phpMyAdmin|PHPMYADMIN|' \
    'scripts|setup|sqladmin|sql-admin|submitticket|' \
    'temp|upload|w00tw00t|webadmin|' \
    'wootwoot|WootWoot|WooTWooT|wp-|xmlrpc)'
  )
  # FAIL2BAN_QUERY = Regexp.compile(ENV['FAIL2BAN_QUERY'] || '\/etc\/passwd')
  Rack::Attack.blocklist('fail2ban pentesters') do |req|
    # `filter` returns truthy value if request fails,
    # or if it's from a previously banned IP
    # so the request is blocked
    Rack::Attack::Fail2Ban.filter(
      "pentesters-#{ClientIp.acquire(req)}",
      maxretry: FAIL2BAN_MAXRETRY,
      findtime: FAIL2BAN_FINDTIME,
      bantime: FAIL2BAN_BANTIME
    ) do
      # The count for the IP is incremented if the return value is truthy
      FAIL2BAN_PATH.match(req.path)
      # || FAIL2BAN_QUERY.match(CGI.unescape(req.query_string))
    end
  end
end
# rubocop: enable Style/IfUnlessModifier, Style/MethodCalledOnDoEndBlock
# rubocop: enable Style/ClassAndModuleChildren
