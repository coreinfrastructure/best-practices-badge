# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is a simple list of records with column "forbidden" of all
# "known bad passwords". There's not anything to it; ActiveRecord handles it.

class BadPassword < ApplicationRecord
  # rubocop:disable Metrics/MethodLength
  def self.bad_passwords_from_file
    require 'zlib'
    bad_password_array = []
    Zlib::GzipReader.open('raw-bad-passwords-lowercase.txt.gz') do |gz|
      gz.each_line do |line|
        bad_password_array.push({ forbidden: line.chomp.downcase.freeze })
      end
    end
    bad_password_array
  end
  # rubocop:enable Metrics/MethodLength

  # Force load into the database the list of bad passwords.
  def self.force_load
    BadPassword.delete_all
    bad_password_array = bad_passwords_from_file
    # Update all in one transaction, or it will take a *long* time
    transaction do
      # TODO: Speed this up with Rails 6's "insert_all!" (bulk insert)
      BadPassword.create!(bad_password_array)
    end
  end

  # Return true iff forbidden exists in BadPassword, but don't do SQL logging.
  # The production environment runs at :info debug level, which
  # doesn't log individual SQL queries. However, it's possible to change the
  # log level to :debug (0), or start the application in a non-production
  # setting that has debug level. This is the default during testing,
  # for example. At :debug level, individual
  # SQL queries *are* logged. To prevent accidentally revealing passwords
  # through the logs, we will *not* check the bad password database
  # at log level 0 (debug).
  #
  # I originally wanted to use Rails.logger.silence to do this.
  # However, there is no clear evidence it's
  # thread-safe, and much evidence it isn't. Simply disabling logging of the
  # global logging object is *not* okay. If we simply silenced logging,
  # we would sometimes disable logging of other events.
  # Since we only check for unlogged passwords as an extra help for users,
  # losing this isn't a problem.

  # Should we do the bad password lookups?
  # We will do a lookup in the test environment *or* if the log level
  # is not debug log level (level 0).
  # The ||= is because Rails reloads. It's okay if it recalculates this
  # twice if it's false, it'll produce the same result each time.
  DO_LOOKUPS ||= Rails.env.test? || (Rails.logger.level != 0)

  # Provide warning if we are NOT actually doing the bad password lookups.
  # We want to make sure we avoid logging those lookups, by not doing them,
  # but we want to warn that it's happening.
  Rails.logger.info('Bad password lookups disabled') unless DO_LOOKUPS

  def self.unlogged_exists?(forbidden)
    DO_LOOKUPS && exists?(forbidden)
  end
end
