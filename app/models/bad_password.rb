# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This is a simple list of HMAC (keyed cryptographically hashed) records with
# column "forbidden_hash" of all "lowercased known bad passwords".
# There's not much to it; ActiveRecord handles quickly seeing if it exists.

# In *production*, make sure you set 'BADGEAPP_BADPWKEY' to a secret key
# and initialize this database table.
# You can (re)initialize this database table at any time by running:
# rake update_bad_password_db

class BadPassword < ApplicationRecord
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

  # Use this key in HMAC to encrypt and cryptographically hash
  # the 'bad passwords' and any password used to
  # compare them. As a result, at runtime the database only sees HMACs
  # of passwords, never passwords, when comparing to the bad password table.
  # This isn't necessary for security; passwords are only
  # *stored* in bcrypt format. However, if an attacker manages to read
  # communication lines from the app to the *running* database system,
  # or control the running database system itself,
  # this measure will ensure that the attacker never gets
  # access to unencrypted passwords.
  # In an effort to be max-hard on
  # attackers, we'll use a keyed cryptographic hash, and whine when we don't
  # get a key. Then an attacker can only get a keyed HMAC, even if
  # they can see the database communication in real time (including via a
  # log of SQL queries). Even a rainbow table won't help if the key isn't known.
  # We *allow* execution with a known key, because that way we can run tests
  # or do interactive development without having to rebuild the database
  # each time.
  # We use SHA-512, so 128 bytes (512 bits) of key is recommended.
  # Here's one way to create a key: openssl rand -hex 128
  DEFAULT_BADPWKEY ||= 'a5' * 128 # For testing and development
  BADPWKEY ||= ENV['BADGEAPP_BADPWKEY'] || DEFAULT_BADPWKEY
  Rails.logger.info('BADGEAPP_BADPWKEY unset') if BADPWKEY == DEFAULT_BADPWKEY
  BADPWKEY_BYTES ||= [BADPWKEY].pack('H*')

  # Return string representation of HMAC of pw (password)
  def self.hash_password(pw)
    OpenSSL::HMAC.hexdigest('SHA512', BADPWKEY_BYTES, pw)
  end

  # Load "bad passwords" from a file, up to "max" count.
  # rubocop:disable Metrics/MethodLength
  def self.bad_passwords_from_file(max = nil)
    require 'zlib'
    bad_password_array = []
    count = 0
    Zlib::GzipReader.open('raw-bad-passwords-lowercase.txt.gz') do |gz|
      gz.each_line do |line|
        pw = line.chomp.downcase.freeze
        hashed_pw = hash_password(pw)
        bad_password_array.push({ forbidden_hash: hashed_pw })
        count += 1
        break unless max.nil? || max < count
      end
    end
    bad_password_array
  end
  # rubocop:enable Metrics/MethodLength

  # Force load into the database the list of bad passwords, up to max number.
  # We have a "max" so that testing doesn't take forever.
  def self.force_load(max = nil)
    BadPassword.delete_all
    bad_password_array = bad_passwords_from_file(max)
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
  # losing this functionality isn't a serious problem.
  # It's better to not check for bad passwords to ensure *no* password
  # is ever exposed.
  #
  # Note that we only checked keyed cryptographic hashes. That way, even
  # if an attacker manages to see the queries, they'll also need the key
  # before they can *start* doing brute-force searches for a password.

  def self.unlogged_exists?(pw)
    pw_hash = hash_password(pw.downcase)
    DO_LOOKUPS && exists?(forbidden_hash: pw_hash)
  end
end
