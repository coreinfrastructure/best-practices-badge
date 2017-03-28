# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
SecureHeaders::Configuration.default do |config|
  normal_src = ["'self'"]
  if ENV['PUBLIC_HOSTNAME']
    fastly_alternate = 'https://' + ENV['PUBLIC_HOSTNAME'] +
                       '.global.ssl.fastly.net'
    normal_src += [fastly_alternate]
  end
  config.hsts = "max-age=#{20.years.to_i}; includeSubDomains; preload"
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  config.referrer_policy = 'no-referrer-when-downgrade'
  # Configure CSP
  config.csp = {
    # Control information sources
    default_src: normal_src,
    img_src: ['secure.gravatar.com', 'avatars.githubusercontent.com', "'self'"],
    object_src: ["'none'"],
    style_src: normal_src,
    # Harden CSP against attacks in other ways
    base_uri: ["'self'"],
    block_all_mixed_content: true, # see http://www.w3.org/TR/mixed-content/
    frame_ancestors: ["'none'"],
    form_action: ["'self'"], # This counters some XSS busters
    plugin_types: ["'none'"]
  }
  config.cookies = {
    secure: true, # mark all cookies as Secure
    # NOTE: The following marks all cookies as HttpOnly.  This will need
    # need to change if there's more JavaScript-based interaction.
    httponly: true,
    # Use SameSite to counter CSRF attacks when browser supports it
    # https://www.sjoerdlangkemper.nl/2016/04/14/
    # preventing-csrf-with-samesite-cookie-attribute/
    samesite: {
      strict: false # mark all cookies as SameSite=Lax (not Strict)
    }
  }
  # Not using Public Key Pinning Extension for HTTP (HPKP).
  # Yes, it can counter some attacks, but it can also cause a lot of problems;
  # one wrong move can render the site useless, and it makes it hard to
  # switch CAs if the CA behaves badly.
end
# rubocop:enable Metrics/BlockLength

# override default configuration
SecureHeaders::Configuration.override(:allow_github_form_action) do |config|
  config.csp[:form_action] += ['github.com']
end
