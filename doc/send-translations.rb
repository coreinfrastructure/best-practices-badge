#!/usr/bin/ruby
# frozen_string_literal: true

# Push all translations in the YAML file(s) listed on the command line to
# translation.io that have different values. Unchanged values left unchanged.
# We presume these are *key-based* translations, and that the YAML file's
# topmost entry is the locale.
# Usage:
# send-translations [--real] YAML_FILE+
# Example:
# send-translations config/locales/translation.de.yml
#
# Omitting "--real" performs a test run without actually sending anything.
#
# You MUST first set the environment variable API_KEY for translation.io using:
# export API_KEY='...'
# To get API_KEY, sign in to translation.io, list projects, choose
# dropdown (down arrow) to the right of the relevant, select "Settings".

# Copyright 2020-, the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# We ASSUME that the input YAML file is trusted.
# We use safe_load on the YAML file to reduce security risks,
# but YAML readers are often trusting, so it's
# better to make sure the YAML is okay first.
# We also trust translation.io & assume it's not trying to attack us.

# For more info on the translation.io API, see:
# - https://translation.io/docs/api

# This script is used rarely, only by trusted people, and is short,
# so we're not going to worry about many rubocop rules.
# We also do things like use system() to run curl; if performance were
# more important we could do other things.

# rubocop:disable Style/GlobalVars
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:disable Metrics/BlockNesting

require 'json'
require 'yaml'
require 'English' # Use clearer global variable names like $CHILD_STATUS

$REAL = false

# $CURRENT_TRANSLATIONS[lang][key] has segment info for the translation
# in language `lang` for key `key`
$CURRENT_TRANSLATIONS = {}

# SOURCE[key] has the original (source) info
$SOURCE = {}

# Get API key - warn very early if we can't get it!
$API_KEY = ENV.fetch('API_KEY', nil)
if $API_KEY.nil? || $API_KEY == ''
  STDERR.puts 'Error: Need API_KEY environment variable'
  exit 1
end

# Set $SOURCE with single-level "x.y.z" keys
def convert_source(key, data)
  if data.is_a?(Hash)
    data.each do |subkey, subdata|
      subkey_fullname = key + (key == '' ? '' : '.') + subkey
      convert_source(subkey_fullname, subdata)
    end
  elsif data.is_a?(String)
    $SOURCE[key] = data
  else
    STDERR.puts "Source with unexpected type #{key} - halting"
    exit 1
  end
end

# Process the source file if it hasn't been already.
# For now, we'll assume it's in English (en.yml) in the same directory.
# We should add options to increase flexibility.
def ensure_source_processed(translated_filename)
  return unless $SOURCE.empty?

  source_filename = File.dirname(translated_filename) + '/en.yml'
  source_contents = File.read(source_filename)
  original_source = YAML.safe_load(source_contents)
  convert_source('', original_source['en'])
end

# Load from translation.io the translations for language lang into
# $CURRENT_TRANSLATIONS[lang]
def load_language(lang)
  puts "Loading current translations for language #{lang}"
  system(
    'curl -X GET ' \
    "'https://translation.io/api/v1/segments.json?target_language=#{lang}' " \
    "-H 'x-api-key: #{$API_KEY}' > ,full-list"
  )
  current_translations_file_contents = File.read(',full-list')
  current_translations_json = JSON.parse(current_translations_file_contents)

  if current_translations_json.key?('errors')
    puts 'Error:'
    puts current_translations_json['errors']
    exit 1
  end

  # Initialize hash in CURRENT_TRANSLATIONS for this new language
  $CURRENT_TRANSLATIONS[lang] = {}

  # Reorganize so that $CURRENT_TRANSLATIONS[lang][key] contains segment
  # information that translations.io provides:
  # id, key, target_language, target, etc.
  current_translations_json['segments'].each do |segment|
    # Work around bug in Rubocop
    if segment['target_language'] != lang
      STDERR.puts "Error: Expected language #{lang} in segment #{segment}"
      exit 1
    end
    $CURRENT_TRANSLATIONS[lang][segment['key']] = segment
  end
end

# If real, use PATCH to change segment id's translation to new_value
# Return true iff successful
def change_translation(id, new_value)
  # puts("#{id} : #{new_value}")
  return true unless $REAL

  new_value_json = { 'target' => new_value }.to_json
  # NOTE: This popen invocation does NOT go through the shell,
  # so we do not use shell escapes.
  IO.popen(
    [
      'curl', '-i',
      '-H', "x-api-key: #{$API_KEY}",
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

# If real, use POST to segment id's translation to new_value
# Return true iff successful
def post_translation(key, lang, source, new_value)
  return true unless $REAL

  new_value_json = {
    'target_language' => lang,
    'type' => 'key',
    'key' => key,
    'source' => source,
    'target' => new_value
  }.to_json
  # NOTE: This popen invocation does NOT go through the shell,
  # so we do not use shell escapes.
  # POST https://translation.io/api/v1/segments(.json)
  IO.popen(
    [
      'curl', '-i',
      '-H', "x-api-key: #{$API_KEY}",
      '-H', 'content-type: application/json',
      '--request', 'POST',
      'https://translation.io/api/v1/segments.json',
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
def process_data(lang, key, data)
  if data.is_a?(Hash)
    data.each do |subkey, subdata|
      subkey_fullname = key + (key == '' ? '' : '.') + subkey
      process_data(lang, subkey_fullname, subdata)
    end
  elsif data.is_a?(String)
    if $CURRENT_TRANSLATIONS[lang].key?(key)
      # Potential change to an existing translation
      this_current_translation = $CURRENT_TRANSLATIONS[lang][key]['target'].rstrip
      new_translation = data.rstrip
      if this_current_translation != new_translation
        # Translation has changed!
        id = $CURRENT_TRANSLATIONS[lang][key]['id']
        puts "CHANGE TRANSLATION #{lang} KEY \"#{key}\""
        puts " \"#{this_current_translation}\""
        puts "=> id: #{id}"
        puts " \"#{new_translation}\""
        puts
        if !change_translation(id, new_translation)
          STDERR.puts "Failed to update #{key} - halting"
          exit 1
        end
      end
    else
      # Entirely NEW entry.
      new_translation = data
      if !$SOURCE.key?(key)
        STDERR.puts "Source does not have key #{key}"
        exit 1
      end
      source = $SOURCE[key]
      puts "ADD TRANSLATION #{lang} KEY \"#{key}\":"
      puts " \"#{source}\""
      puts ' =>'
      puts " \"#{new_translation}\""
      puts
      if !post_translation(key, lang, source, new_translation)
        STDERR.puts "Failed to insert new translation for #{key} - halting"
        exit 1
      end
    end
  elsif data.nil?
    # Ignore nil values
  else
    # Crash, something went wrong
    STDERR.puts "Error: Bad class. Value '#{data}' has type #{data.class}"
    exit 1
  end
end

def process_file(filename)
  puts "Processing file #{filename}"
  ensure_source_processed(filename)
  # Load file with new translations for language LANG
  new_text_file_contents = File.read(filename)
  # Convert to data set
  new_text_data = YAML.safe_load(new_text_file_contents)
  # Loop through all languages in filename (typically there's only 1)
  new_text_data.each do |lang, lang_values|
    load_language(lang) unless $CURRENT_TRANSLATIONS.key?(lang)
    process_data(lang, '', lang_values)
  end
end

# Process arguments
ARGV.each do |arg|
  if arg == '--real'
    $REAL = true
    puts 'SAVING VALUES FOR REAL!'
  elsif arg.start_with?('-')
    STDERR.puts "Unknown option: #{arg}"
    exit 1
  else
    process_file arg
  end
end

# rubocop:enable Style/GlobalVars
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:enable Metrics/BlockNesting
