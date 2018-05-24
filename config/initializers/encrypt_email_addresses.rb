# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Setup the keys for hashing and encrypting email addresses.
# These keys protect the data at rest (e.g., so that user addresses
# are not immediately revealed in backups).

BITS_PER_HEX_DIGIT = 4

BITS_OF_EMAIL_HASH_KEY = 256
DIGITS_OF_EMAIL_HASH_KEY = BITS_OF_EMAIL_HASH_KEY / BITS_PER_HEX_DIGIT

BITS_OF_EMAIL_ENCRYPTION_KEY = 256
DIGITS_OF_EMAIL_ENCRYPTION_KEY =
  BITS_OF_EMAIL_ENCRYPTION_KEY / BITS_PER_HEX_DIGIT

Rails.application.config.assets.email_hash_key =
  [ENV['EMAIL_HASH_KEY'] || '0' * DIGITS_OF_EMAIL_HASH_KEY].pack('H*')

Rails.application.config.assets.email_encrypted_key =
  [
    ENV['EMAIL_ENCRYPTED_KEY'] || '0' * DIGITS_OF_EMAIL_ENCRYPTION_KEY
  ].pack('H*')
