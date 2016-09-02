# frozen_string_literal: true
SecureHeaders::Configuration.default do |config|
  normal_src = ["'self'"]
  if ENV['PUBLIC_HOSTNAME']
    fastly_alternate = 'https://' + ENV['PUBLIC_HOSTNAME'] +
                       '.global.ssl.fastly.net'
    normal_src += [fastly_alternate]
  end
  config.hsts = 'max-age=#{20.years.to_i}; includeSubdomains; preload'
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  # Configure CSP
  config.csp = {
    default_src: normal_src,
    img_src: normal_src,
    object_src: normal_src,
    style_src: normal_src
  }
  # Not using Public Key Pinning Extension for HTTP (HPKP).
  # Yes, it can counter some attacks, but it can also cause a lot of problems;
  # one wrong move can render the site useless, and it makes it hard to
  # switch CAs if the CA behaves badly.
end
