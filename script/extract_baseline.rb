#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require_relative '../lib/baseline_html_parser'
require 'json'
require 'yaml'

# Read the HTML source
html_file = 'tmp/baseline_source.html'
unless File.exist?(html_file)
  puts "Error: #{html_file} not found"
  puts "Run: curl -s 'https://baseline.openssf.org/versions/2025-10-10' -o #{html_file}"
  exit 1
end

puts "Reading HTML from #{html_file}..."
html_content = File.read(html_file)

# Parse the HTML
parser = BaselineHtmlParser.new(html_content)
controls = parser.parse

puts "Extracted #{controls.length} controls"

# Save as JSON for easy review
json_file = 'tmp/baseline_extracted.json'
File.write(json_file, JSON.pretty_generate(controls))
puts "Saved JSON to: #{json_file}"

# Save as YAML in our criteria format
yaml_data = {
  '_metadata' => {
    'source' => 'OpenSSF Baseline HTML',
    'source_url' => 'https://baseline.openssf.org/versions/2025-10-10',
    'extracted_at' => Time.now.iso8601,
    'auto_generated' => true,
    'total_controls' => controls.length
  }
}

# Group by maturity level
controls.group_by { |c| c[:maturity_level].first }
        .each do |level, level_controls|
  level_key = "baseline-#{level}"
  yaml_data[level_key] = {}

  # Group by category
  level_controls.group_by { |c| c[:category] }
                .each do |category, cat_controls|
    yaml_data[level_key][category] = {}
    yaml_data[level_key][category]['Controls'] = {}

    cat_controls.each do |control|
      yaml_data[level_key][category]['Controls'][control[:field_name]] = {
        'category' => 'MUST',
        'description' => control[:requirement],
        'details' => control[:recommendation],
        'met_url_required' => true,
        'original_id' => control[:original_id]
      }
    end
  end
end

yaml_file = 'tmp/baseline_extracted.yml'
File.write(yaml_file, yaml_data.to_yaml)
puts "Saved YAML to: #{yaml_file}"

# Print summary
puts "\nSummary by maturity level:"
controls.group_by { |c| c[:maturity_level].first }
        .sort.each do |level, level_controls|
  puts "  Level #{level}: #{level_controls.length} controls"
end

puts "\nSummary by category:"
controls.group_by { |c| c[:category] }
        .sort.each do |category, cat_controls|
  puts "  #{category}: #{cat_controls.length} controls"
end

puts "\nFirst 3 controls:"
controls.first(3).each do |control|
  puts "  #{control[:original_id]} (#{control[:field_name]})"
  puts "    Requirement: #{control[:requirement][0..80]}..."
  puts
end
