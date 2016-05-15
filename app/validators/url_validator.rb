# frozen_string_literal: true
class UrlValidator < ActiveModel::EachValidator
  # The URL validation rules are somewhat overly strict, but should serve;
  # the idea is to prevent attackers from inserting redirecting URLs
  # that can sometimes be used to attack third-party sites via the BadgeApp.
  # For example, this does *not* include "?...", "%..", or ones with <).
  # We can gradually loosen this if needed.  Note that this pattern is
  # more restrictive than the ones we allow in markdown justifications,
  # because the BadgeApp doies *not* follow those URLs for further processing.
  # This regex is our creation, because we're trying to prevent certain URLs
  # that by *spec* are legal.  The first part is an expression of the DNS spec,
  # the latter simply limits the character set used in the path.
  URL_REGEX =
    %r{\A(|https?://[A-Za-z0-9][-A-Za-z0-9_.]*(/[-A-Za-z0-9_.:/+!,#]*)?)\z}

  URL_MESSAGE = 'must begin with http: or https: and use a limited' \
                ' charset'

  def validate_each(record, attribute, value)
    return if value =~ URL_REGEX
    record.errors.add attribute, (options[:message] || URL_MESSAGE)
  end
end
