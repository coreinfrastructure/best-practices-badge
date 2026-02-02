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
#
# After running this script, you should:
# 1. Run `rake assets:precompile` to update the asset pipeline
# 2. Badge widths are auto-detected from SVG files, no manual update needed

OUTPUT_DIR = File.expand_path('../app/assets/images', __dir__)

# Baseline blue colors (progressively darker for higher levels)
# All colors have strong contrast with white text
BASELINE_COLORS = {
  1 => '#007ec6',
  2 => '#0066a1',
  3 => '#004b87'
}.freeze

# Color for in-progress percentage badges (darker orange for better contrast)
PERCENTAGE_COLOR = '#c45500'

# Badge dimensions - balanced for "openssf baseline" text
# Left side: "openssf baseline" (16 chars) - 107px balances compactness with readability
LEVEL_BADGE_LEFT_WIDTH = 107
LEVEL_BADGE_RIGHT_WIDTH = 28 # Just for "1", "2", or "3"
LEVEL_BADGE_WIDTH = LEVEL_BADGE_LEFT_WIDTH + LEVEL_BADGE_RIGHT_WIDTH # 135

# Percentage badge dimensions
PERCENTAGE_BADGE_LEFT_WIDTH = 107
# Right side needs room for construction icon + space + "XX%"
PERCENTAGE_BADGE_RIGHT_WIDTH_1DIGIT = 52   # "🚧 X%"
PERCENTAGE_BADGE_RIGHT_WIDTH_2DIGIT = 60   # "🚧 XX%"

# Text length values (controls letter spacing in SVG)
# Calibrated for proper spacing at font-size 110 with scale(0.1)
LEFT_TEXT_LENGTH = 870         # "openssf baseline" - balanced spacing
LEVEL_NUMBER_LENGTH = 60       # Single digit "1", "2", or "3"
PERCENTAGE_1DIGIT_LENGTH = 340 # "🚧 X%"
PERCENTAGE_2DIGIT_LENGTH = 400 # "🚧 XX%"

# Construction sign emoji for work in progress
CONSTRUCTION_ICON = '🚧'

# Generate the SVG for a baseline level badge (level 1, 2, or 3)
def generate_level_badge(level)
  color = BASELINE_COLORS[level]

  total_width = LEVEL_BADGE_WIDTH
  left_width = LEVEL_BADGE_LEFT_WIDTH
  right_width = LEVEL_BADGE_RIGHT_WIDTH

  # Text positioning (scaled by 0.1, so multiply by 10)
  left_center = (left_width / 2.0 * 10).to_i
  right_center = ((left_width + (right_width / 2.0)) * 10).to_i

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: #{level}"><title>openssf baseline: #{level}</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{color}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110"><text aria-hidden="true" x="#{left_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text x="#{left_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEVEL_NUMBER_LENGTH}">#{level}</text><text x="#{right_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEVEL_NUMBER_LENGTH}">#{level}</text></g></svg>
  SVG
end

# Generate the SVG for a baseline percentage badge (0-99%)
def generate_percentage_badge(pct)
  label = "#{CONSTRUCTION_ICON} #{pct}%"

  # Right width varies: 1 digit (0%-9%) vs 2 digits (10%-99%)
  right_width = pct < 10 ? PERCENTAGE_BADGE_RIGHT_WIDTH_1DIGIT : PERCENTAGE_BADGE_RIGHT_WIDTH_2DIGIT
  left_width = PERCENTAGE_BADGE_LEFT_WIDTH
  total_width = left_width + right_width

  # Text positioning (scaled by 0.1, so multiply by 10)
  left_center = (left_width / 2.0 * 10).to_i
  right_center = ((left_width + (right_width / 2.0)) * 10).to_i

  # Right text length varies: 1 digit vs 2 digits
  right_text_length = pct < 10 ? PERCENTAGE_1DIGIT_LENGTH : PERCENTAGE_2DIGIT_LENGTH

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: in progress #{pct}%"><title>openssf baseline: in progress #{pct}%</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{PERCENTAGE_COLOR}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110"><text aria-hidden="true" x="#{left_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text x="#{left_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{right_text_length}">#{label}</text><text x="#{right_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{right_text_length}">#{label}</text></g></svg>
  SVG
end

# Main execution
puts "Generating baseline badges in #{OUTPUT_DIR}..."

# Generate level badges (1, 2, 3)
[1, 2, 3].each do |level|
  svg = generate_level_badge(level)
  path = "#{OUTPUT_DIR}/badge_baseline_#{level}.svg"
  File.write(path, "#{svg}\n")
  puts "  Generated: badge_baseline_#{level}.svg (width: #{LEVEL_BADGE_WIDTH})"
end

# Generate percentage badges (0-99)
(0..99).each do |pct|
  svg = generate_percentage_badge(pct)
  path = "#{OUTPUT_DIR}/badge_baseline_pct_#{pct}.svg"
  File.write(path, "#{svg}\n")
end
puts '  Generated: badge_baseline_pct_0.svg through badge_baseline_pct_99.svg'

puts <<~DONE

  Done! Generated 3 level badges and 100 percentage badges.

  Next steps:
  1. Run `rake assets:precompile` to update the asset pipeline
  2. Badge widths are auto-detected from SVG files (no manual update needed)
DONE
