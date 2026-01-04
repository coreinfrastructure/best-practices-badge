# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Load the initializer code that defines periodically_run_gc_compact
require_relative '../../../config/initializers/gc_compact_thread'

class GcCompactThreadTest < ActiveSupport::TestCase
  # Test the periodic GC compactor function runs at all.
  # This is a lame test, but it ensures that it at least doesn't crash
  # on one pass, and we don't need to delve into its functionality
  # more than that.
  test 'periodically_run_gc_compact runs one_time=true and interval=1' do
    assert GcCompactThread.periodically_run_gc_compact(1, true)
  end
end
