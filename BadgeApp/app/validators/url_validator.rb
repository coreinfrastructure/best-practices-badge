class UrlValidator < ActiveModel::EachValidator
  # The URL validation rules are somewhat overly strict, but should serve;
  # the idea is to prevent attackers from inserting redirecting URLs
  # that can sometimes be used to attack (e.g., "?...", or ones with <).
  URL_REGEX =
    %r{\A(|https?:\/\/[A-Za-z0-9][-A-Za-z0-9_.\/]*(\/[-A-Za-z0-9_.\/\+,#]*)?)\z}
    .freeze
  URL_MESSAGE = 'must begin with http: or https: and use a limited' \
                ' charset'.freeze

  def validate_each(record, attribute, value)
    return if value =~ URL_REGEX
    record.errors.add attribute, (options[:message] || URL_MESSAGE)
  end
end
