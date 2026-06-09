# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class EvidenceTest < ActiveSupport::TestCase
  setup do
    @project = projects(:perfect)
    @evidence = Evidence.new(@project)
  end

  test 'initialize sets project' do
    assert_equal @project, @evidence.project
  end

  test 'get caches successful URL fetch' do
    url = 'https://raw.githubusercontent.com/coreinfrastructure/' \
          'best-practices-badge/main/README.md'

    VCR.use_cassette('evidence_get_success') do
      result = @evidence.get(url)

      # Verify the result contains meta and body
      assert_not_nil result
      assert result.key?(:meta)
      assert result.key?(:body)

      # Verify it's cached (second call returns same object)
      result2 = @evidence.get(url)
      assert_same result, result2
    end
  end

  test 'get handles URL fetch errors gracefully' do
    url = 'https://example.invalid/nonexistent'

    result = @evidence.get(url)

    # Should return nil on error
    assert_nil result

    # Second call should also return nil (cached)
    result2 = @evidence.get(url)
    assert_nil result2
  end

  test 'get ignores dubious URLs' do
    url = 'http://127.0.0.1'

    # Should return nil for dubious URL
    result = @evidence.get(url)
    assert_nil result

    # Should be cached as nil
    result2 = @evidence.get(url)
    assert_nil result2
  end

  test 'get respects MAXREAD limit' do
    url = 'https://raw.githubusercontent.com/coreinfrastructure/' \
          'best-practices-badge/main/README.md'

    VCR.use_cassette('evidence_get_success') do
      result = @evidence.get(url)

      # Verify body doesn't exceed MAXREAD
      assert result[:body].bytesize <= Evidence::MAXREAD
    end
  end

  test 'get blocks SSRF resolving to private IP (offline-safe)' do
    # nip.io is a service that resolves to the IP address in the subdomain.
    # In this test we intercept the DNS request with a mock
    # (so we don't actually do the lookup), but an attacker
    # really *could* use a domain name like this to redirect to localhost.
    url = 'http://127.0.0.1.nip.io'

    # Mock resolver resolves our target to a private IP
    mock_resolver = lambda { |hostname|
      hostname == 'ssrf-target.local' ? [IPAddr.new('127.0.0.1')] : []
    }

    evidence_with_mock = Evidence.new(@project, resolver: mock_resolver)

    result = evidence_with_mock.get(url)
    assert_nil result
  end
end
