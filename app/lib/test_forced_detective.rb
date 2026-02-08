# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Test-only detective that forces an override when given specific input.
# This detective is used to test override detection and warning paths
# in projects_controller without needing to mock Chief behavior.
#
# Only active in test environment. Only forces override for specific test URL.
class TestForcedDetective < Detective
  INPUTS = [:repo_url].freeze
  OUTPUTS = [:description_good_status].freeze
  OVERRIDABLE_OUTPUTS = [:description_good_status].freeze

  # @return [Hash] Forced override for specific test URL, empty otherwise
  def analyze(_evidence, current)
    # Only force override for specific test URL pattern (non-GitHub to avoid VCR)
    repo_url = current[:repo_url]

    # Special URL to test Chief exception handling
    if repo_url == 'https://example.com/test/chief-failure'
      raise StandardError, 'Test chief failure for coverage'
    end

    return {} unless repo_url == 'https://example.com/test/force-override'

    {
      description_good_status: {
        value: 'Met',
        confidence: 5, # High confidence triggers forced override
        explanation: 'Test override for automated override detection coverage'
      }
    }
  end
end
