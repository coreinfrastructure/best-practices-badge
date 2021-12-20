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
end
