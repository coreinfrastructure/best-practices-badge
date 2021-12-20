# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Enable garbage collection (GC) profiling.
# Garbage collection affects performance.
# Note that New Relic can use this data.
# https://docs.newrelic.com/docs/agents/ruby-agent/features/garbage-collection
# #gc_setup
GC::Profiler.enable
