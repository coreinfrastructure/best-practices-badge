#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Dump cache metrics from tmp/cache_metrics.json (written by running server).
#
# Usage: script/cache_metrics_report.rb
#
# Must have started server with: CACHE_PROFILE=1 rails s
# Metrics are saved every 100 cache operations to tmp/cache_metrics.json

require 'json'

METRICS_FILE = File.join(__dir__, '..', 'tmp', 'cache_metrics.json')

unless File.exist?(METRICS_FILE)
  warn "No metrics file found at #{METRICS_FILE}"
  warn 'Start server with CACHE_PROFILE=1 and run some requests first.'
  exit 1
end

metrics = JSON.parse(File.read(METRICS_FILE), symbolize_names: true)

if metrics.empty?
  warn 'Metrics file is empty. Run more requests with CACHE_PROFILE=1.'
  exit 1
end

# Sort by total allocations descending
metrics.sort_by! { |m| -m[:total_allocs] }

# rubocop:disable Layout/LineLength
puts 'Cache Key                                                 Hits   Miss    Hit%   TotAlloc AvgAlloc'
# rubocop:enable Layout/LineLength
puts '-' * 95

metrics.each do |m|
  total = m[:hits] + m[:misses]
  hit_pct = total.positive? ? (m[:hits] * 100.0 / total).round(1) : 0.0
  avg = total.positive? ? (m[:total_allocs] / total).round(0) : 0
  puts format(
    '%<key>-55s %<hits>6d %<miss>6d %<pct>6.1f%% %<alloc>10d %<avg>8d',
    key: m[:key][0, 55], hits: m[:hits], miss: m[:misses],
    pct: hit_pct, alloc: m[:total_allocs], avg: avg
  )
end

puts
puts 'Interpretation:'
puts '  - High TotAlloc + Low Hit%: Consider removing (overhead > benefit)'
puts '  - High Hit% + Low AvgAlloc: Good cache (keep)'
puts '  - Low hits overall: May not be exercised enough to judge'
