# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class FastlyRailsTest < ActiveSupport::TestCase
  setup do
  end

  # Test that the system will keep running even if a bad key is given.
  # We don't test for a "good" key because we don't want to accidentally
  # include a valid Fastly key in the test data
  test 'purge_by_key fails on bad key' do
    VCR.use_cassette('fastly_no_key') do
      # *Force* use of the key
      FastlyRails.purge_by_key('foo', true)
    end
  end

  # Test that the system will keep running even if the CDN (Fastly)
  # port is dead. We created this cassette by modifying
  # app/lib/fastly_rails.rb to try to access a useless port, then edited
  # the cassette fastly_deadport to remove the port number.
  test 'purge_by_key keeps working even if port fails' do
    # *Force* use of the key, since we don't have one set.
    # We set a nonsense localhost base  for this test.
    # VCR can't record "failure to connect", so we'll
    # instead force a failure to connect so we can test its handling.
    FastlyRails.purge_by_key('foo', true, 'https://localhost:0/')
  end

  test 'purge_all keeps working even if port fails' do
    # *Force* use of the key, since we don't have one set.
    # We set a nonsense localhost base  for this test.
    # VCR can't record "failure to connect", so we'll
    # instead force a failure to connect so we can test its handling.
    FastlyRails.purge_all(true, 'https://localhost:0/')
  end
end
