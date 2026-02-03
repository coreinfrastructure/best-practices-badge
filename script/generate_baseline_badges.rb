#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Generate baseline badge SVG files
#
# This script generates all baseline badge images:
# - Level badges: badge_baseline_1.svg, badge_baseline_2.svg, badge_baseline_3.svg
# - Percentage badges: badge_baseline_pct_0.svg through badge_baseline_pct_99.svg
#
# Usage:
#   ruby script/generate_baseline_badges.rb

OUTPUT_DIR = File.expand_path('../app/assets/images', __dir__)

# Baseline blue colors (progressively darker for higher levels)
BASELINE_COLORS = {
  1 => '#007ec6',
  2 => '#0066a1',
  3 => '#004b87'
}.freeze

# Color for in-progress percentage badges
PERCENTAGE_COLOR = '#c45500'

# Construction sign emoji for work in progress
CONSTRUCTION_ICON = '🚧'

# Generate the SVG for a baseline level badge (level 1, 2, or 3)
def generate_level_badge(level)
  color = BASELINE_COLORS[level]
  left_width = 103  # "openssf baseline" ~93px at font-size 11 + margins
  right_width = 18  # single digit + margins
  total_width = left_width + right_width
  left_center = left_width / 2.0
  right_center = left_width + (right_width / 2.0)

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: #{level}"><title>openssf baseline: #{level}</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{color}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="11"><text aria-hidden="true" x="#{left_center}" y="15" fill="#010101" fill-opacity=".3">openssf baseline</text><text x="#{left_center}" y="14">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="15" fill="#010101" fill-opacity=".3">#{level}</text><text x="#{right_center}" y="14">#{level}</text></g></svg>
  SVG
end

# Generate the SVG for a baseline percentage badge (0-99%)
def generate_percentage_badge(pct)
  label = "#{CONSTRUCTION_ICON} #{pct}%"
  left_width = 103
  right_width = pct < 10 ? 38 : 46 # icon + digits + margins
  total_width = left_width + right_width
  left_center = left_width / 2.0
  right_center = left_width + (right_width / 2.0)

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: in progress #{pct}%"><title>openssf baseline: in progress #{pct}%</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{PERCENTAGE_COLOR}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="11"><text aria-hidden="true" x="#{left_center}" y="15" fill="#010101" fill-opacity=".3">openssf baseline</text><text x="#{left_center}" y="14">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="15" fill="#010101" fill-opacity=".3">#{label}</text><text x="#{right_center}" y="14">#{label}</text></g></svg>
  SVG
end

# Main execution
puts "Generating baseline badges in #{OUTPUT_DIR}..."

# Generate level badges (1, 2, 3)
[1, 2, 3].each do |level|
  svg = generate_level_badge(level)
  path = "#{OUTPUT_DIR}/badge_baseline_#{level}.svg"
  File.write(path, "#{svg}\n")
  puts "  Generated: badge_baseline_#{level}.svg"
end

# Generate percentage badges (0-99)
(0..99).each do |pct|
  svg = generate_percentage_badge(pct)
  path = "#{OUTPUT_DIR}/badge_baseline_pct_#{pct}.svg"
  File.write(path, "#{svg}\n")
end
puts '  Generated: badge_baseline_pct_0.svg through badge_baseline_pct_99.svg'

puts "\nDone! Generated 3 level badges and 100 percentage badges. Now run:"
puts 'rake assets:precompile'
