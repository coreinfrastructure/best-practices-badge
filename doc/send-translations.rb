#!/usr/bin/ruby
# frozen_string_literal: true

# Copyright 2020-, the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Push all translations in LANG with different values to translation.io.
# This could be generalized later if desired, but I'm currently trying
# to solve a very specific problem.

# You MUST set environment variable API_KEY for translation.io using:
# export API_KEY='...'
# To get API_KEY, sign in to translation.io, list projects, choose
# dropdown (down arrow) to the right of the relevant, select "Settings".

# We ASSUME that the input YAML file is trusted.
# We use safe_load on the YAML file to reduce security risks,
# but YAML readers are often trusting, so it's
# better to make sure the YAML is okay first.
# We also trust translation.io & assume it's not trying to attack us.

# For more info on the translation.io API, see:
# # https://translation.io/docs/api

# This is a short "quickie script" used rarely, and only by trusted people,
# so we're not going to worry about many rubocop rules.
# Since we don't intend to maintain it often (if at all), and it's short
# overall, a little extra complexity is fine.
# We also do things like use system() to run curl; if performance were
# more important we could do other things.

# rubocop:disable Style/GlobalVars
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:disable Metrics/BlockNesting

require 'json'
require 'yaml'
require 'English' # Use clearer global variable names like $CHILD_STATUS

LANG = 'de'

puts "Starting to transmit translations in #{LANG}."

# Load file with new translations for language LANG
new_text_filename =
  "#{Dir.home}/best-practices-badge/config/locales/translation.#{LANG}.yml"
new_text_file_contents = File.read(new_text_filename)
new_text_yaml = YAML.safe_load(new_text_file_contents)
# new_text_yaml.dump()
# puts new_text_yaml

# Retrieve current translations for language LANG
API_KEY = ENV['API_KEY']
if API_KEY.nil? || API_KEY == ''
  puts 'Need API_KEY environment variable'
  exit 1
end
system(
  'curl -X GET ' \
  "'https://translation.io/api/v1/segments.json?target_language=#{LANG}' " \
  "-H 'x-api-key: #{API_KEY}' > ,full-list"
)
current_translations_file_contents = File.read(',full-list')
current_translations_json = JSON.parse(current_translations_file_contents)

# Reorganize so that current_translations[key] contains that segment
# translations.io provides:
# {"segments"=>[ ... list ... ]
# where each one has id, key, target_language, target, etc.
$current_translations = {}
current_translations_json['segments'].each do |segment|
  $current_translations[segment['key']] = segment
  # Work around bug in Rubocop
  # rubocop:disable Style/Next
  if segment['target_language'] != LANG
    puts 'Error: Wrong language in:'
    puts segment.to_s
    exit 1
  end
  # rubocop:enable Style/Next
end

# Use PATCH to change segment id's translation to new_value
# Return error code (0 is success)
def change_translation(id, new_value)
  # puts("#{id} : #{new_value}")
  # Add the following line to prevent ACTUAL changing of the translation:
  # return true
  new_value_json = { 'target' => new_value }.to_json
  # Note: This popen invocation does NOT go through the shell,
  # so we do not use shell escapes.
  IO.popen(
    [
      'curl', '-i',
      '-H', "x-api-key: #{API_KEY}",
      '-H', 'content-type: application/json',
      '--request', 'PATCH',
      "https://translation.io/api/v1/segments/#{id}.json",
      '--data', new_value_json
    ]
  ) do |io|
    curl_output = io.read
    puts curl_output # Very useful for debugging!
    io.close
    $CHILD_STATUS.success? # Return whether or not we succeeded
  end
end

# Handle data with full key value key
def process_data(key, data)
  if data.is_a?(Hash)
    data.each do |subkey, subdata|
      subkey_fullname = key + (key == '' ? '' : '.') + subkey
      process_data(subkey_fullname, subdata)
    end
  elsif data.is_a?(String)
    if $current_translations.key?(key)
      this_current_translation = $current_translations[key]['target'].rstrip
      new_translation = data.rstrip
      if this_current_translation != new_translation
        id = $current_translations[key]['id']
        # Translation has changed!
        puts " \"#{key}\": \"#{this_current_translation}\""
        puts "   => id: #{id}, \"#{new_translation}\""
        puts
        if !change_translation(id, new_translation)
          puts "Failed to update #{key} - halting"
          exit 1
        end
      end
    end
  elsif data.nil?
    # Ignore nil values
  else
    # Crash, something went wrong
    puts 'FAILURE!'
    puts data
    puts data.class.to_s
    exit 1
  end
end

process_data('', new_text_yaml[LANG])
#
# rubocop:enable Style/GlobalVars
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:enable Metrics/BlockNesting
