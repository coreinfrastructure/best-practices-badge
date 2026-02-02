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
BASELINE_COLORS = {
  1 => '#007ec6',
  2 => '#0066a1',
  3 => '#004b87'
}.freeze

# Color for in-progress percentage badges (yellow/amber)
PERCENTAGE_COLOR = '#dfb317'

# Badge dimensions
LEVEL_BADGE_WIDTH = 200
LEVEL_BADGE_LEFT_WIDTH = 125
LEVEL_BADGE_RIGHT_WIDTH = 75

PERCENTAGE_BADGE_WIDTH = 166
PERCENTAGE_BADGE_LEFT_WIDTH = 125
PERCENTAGE_BADGE_RIGHT_WIDTH = 41

# Text length values (controls letter spacing in SVG)
# These are calibrated to match the metal series letter spacing ratio.
# Metal series uses ~56 per character (1230/22 for "openssf best practices").
LEFT_TEXT_LENGTH = 900       # "openssf baseline" (16 chars × ~56 = 896)
LEVEL_TEXT_LENGTH = 390      # "level X" (7 chars × ~56 = 392)
PERCENTAGE_1DIGIT_LENGTH = 110  # "X%" (2 chars × ~56 = 112)
PERCENTAGE_2DIGIT_LENGTH = 170  # "XX%" (3 chars × ~56 = 168)

# Generate the SVG for a baseline level badge (level 1, 2, or 3)
def generate_level_badge(level)
  color = BASELINE_COLORS[level]
  label = "level #{level}"

  total_width = LEVEL_BADGE_WIDTH
  left_width = LEVEL_BADGE_LEFT_WIDTH
  right_width = LEVEL_BADGE_RIGHT_WIDTH

  # Text positioning (scaled by 0.1, so multiply by 10)
  left_center = (left_width / 2.0 * 10).to_i
  right_center = ((left_width + (right_width / 2.0)) * 10).to_i

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: #{label}"><title>openssf baseline: #{label}</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{color}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110"><text aria-hidden="true" x="#{left_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text x="#{left_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEVEL_TEXT_LENGTH}">#{label}</text><text x="#{right_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEVEL_TEXT_LENGTH}">#{label}</text></g></svg>
  SVG
end

# Generate the SVG for a baseline percentage badge (0-99%)
def generate_percentage_badge(pct)
  label = "#{pct}%"

  total_width = PERCENTAGE_BADGE_WIDTH
  left_width = PERCENTAGE_BADGE_LEFT_WIDTH
  right_width = PERCENTAGE_BADGE_RIGHT_WIDTH

  # Text positioning (scaled by 0.1, so multiply by 10)
  left_center = (left_width / 2.0 * 10).to_i
  right_center = ((left_width + (right_width / 2.0)) * 10).to_i

  # Right text length varies: 1 digit (0%-9%) vs 2 digits (10%-99%)
  right_text_length = pct < 10 ? PERCENTAGE_1DIGIT_LENGTH : PERCENTAGE_2DIGIT_LENGTH

  <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{total_width}" height="20" role="img" aria-label="openssf baseline: #{label}"><title>openssf baseline: #{label}</title><linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="#{total_width}" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#r)"><rect width="#{left_width}" height="20" fill="#555"/><rect x="#{left_width}" width="#{right_width}" height="20" fill="#{PERCENTAGE_COLOR}"/><rect width="#{total_width}" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110"><text aria-hidden="true" x="#{left_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text x="#{left_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{LEFT_TEXT_LENGTH}">openssf baseline</text><text aria-hidden="true" x="#{right_center}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{right_text_length}">#{label}</text><text x="#{right_center}" y="140" transform="scale(.1)" fill="#fff" textLength="#{right_text_length}">#{label}</text></g></svg>
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

puts <<~DONE

  Done! Generated 3 level badges and 100 percentage badges.

  Next steps:
  1. Run `rake assets:precompile` to update the asset pipeline
  2. Badge widths are auto-detected from SVG files (no manual update needed)
DONE
