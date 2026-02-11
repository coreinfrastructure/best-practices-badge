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

  test 'get respects MAXREAD limit' do
    url = 'https://raw.githubusercontent.com/coreinfrastructure/' \
          'best-practices-badge/main/README.md'

    VCR.use_cassette('evidence_get_success') do
      result = @evidence.get(url)

      # Verify body doesn't exceed MAXREAD
      assert result[:body].bytesize <= Evidence::MAXREAD
    end
  end
end
