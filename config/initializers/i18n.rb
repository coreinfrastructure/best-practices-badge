# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Here we set the available locales.
#
# Rails requires that locales given (if any) must be an
# available locale by default (I18n.enforce_available_locales = true).
# We build on that by setting the available locales.
#
# The Rails default is as follows (this illustrates some options):
# [:en, :"en-BORK", :"de-CH", :fa, :"en-US", :"en-GB", :ja, :"en-NG", :es,
# :"en-UG", :"ca-CAT", :"en-PAK", :pt, :"de-AT", :nl, :"en-AU", :"en-ZA",
# :"nb-NO", :id, :"en-IND", :"es-MX", :"fi-FI", :ca, :ru, :fr, :"en-CA",
# :ko, :vi, :sv, :"da-DK", :he, :"en-SG", :tr, :"zh-CN", :pl, :it, :sk,
# :de, :"en-au-ocker", :"en-NZ", :"zh-TW", :"pt-BR", :nep, :uk, :ro, :da,
# :hu, :cs]
#
# The order here is English (the source language in this case), followed
# by the locales in English name order. Pagy initialization requires en first.
# This has the useful side-effect that Chinese is listed early, next to
# a Romance language, so it will be *immediately* obvious to users
# that this is the locale selection list.
# We maintain this order elsewhere, to reduce the risk that
# we'll accidentally omit a locale.  For example, see
# config/initializers/translation.rb

I18n.available_locales = %i[en zh-CN es fr de ja pt-BR ru sw].freeze

# Here are the locales we will *automatically* switch to.
# This *may* be the same as I18n.available_locales, but if a locale's
# translation isn't ready we will remove it here.
Rails.application.config.automatic_locales =
  (I18n.available_locales.dup - %i[es sw pt-BR]).freeze

# Automatic_locales must be a subset of I18n.available_locales - check it!
raise InvalidLocale unless
  (Rails.application.config.automatic_locales - I18n.available_locales).empty?

# The rest of the application uses those settings above automatically.
# For example, robots.txt counters crawling in these locales.
# To see how it does that, see:
# app/views/static_pages/robots.text.erb
#

# If we don't have text, fall back to English.  That obviously isn't
# ideal, but it's better to show *some* text to the user than leave it
# a mystery.
# ALSO: Gem i18n 1.1 changed fallbacks to exclude default locale. It says:
# > Please check your Rails app for 'config.i18n.fallbacks = true'.
# > If you're using I18n (>= 1.1.0) and Rails (< 5.2.2), this should be
# > 'config.i18n.fallbacks = [I18n.default_locale]'.
# > If not, fallbacks will be broken in your app by I18n 1.1.x.
Rails.application.config.i18n.fallbacks = [:en]

# Load machine translations using a custom I18n backend with smart fallback.
#
# CRITICAL SECURITY REQUIREMENT:
# Machine translations MUST NOT be added to I18n.load_path because
# translation.io's sync mechanism reads ALL files from I18n.load_path
# and would upload our machine translations to translation.io, making it
# impossible to distinguish between human and machine translations.
#
# WHY NOT CONDITIONAL LOADING (Rails.env.local? check)?
# That would mean test/development see different behavior than production.
# We need consistent behavior across all environments.
#
# SOLUTION: Custom Backend with Smart Fallback
# We load machine translations into a separate backend (not in I18n.load_path),
# then use MachineTranslationFallbackBackend to check human translations first,
# falling through to machine translations only when human is nil/empty.
#
# Result:
# - Machine translations work in ALL environments (production, test, dev)
# - Human translations (when present) always override machine translations
# - Empty/nil values in human translations are treated as "not translated"
# - translation.io never sees machine translations
# - Consistent behavior everywhere

require_relative '../../lib/machine_translation_fallback_backend'

Rails.application.config.after_initialize do
  # CRITICAL SAFETY CHECK: Ensure machine translations are isolated from translation.io
  # translation.io syncs all files in I18n.load_path, so machine translations MUST NOT be there
  machine_translations_dir = Rails.root.join('config', 'machine_translations').to_s
  contaminated_paths = I18n.load_path.select { |path| path.to_s.start_with?(machine_translations_dir) }
  
  if contaminated_paths.any?
    raise <<~ERROR
      CRITICAL CONFIGURATION ERROR: Machine translations detected in I18n.load_path!
      
      The following machine translation files are in I18n.load_path:
      #{contaminated_paths.map { |p| "  - #{p}" }.join("\n")}
      
      This would cause translation.io to sync machine translations, contaminating
      the human translation database and making it impossible to distinguish between
      human and machine translations.
      
      Machine translations MUST be loaded through the custom backend only, not via
      I18n.load_path. Check config/initializers/i18n.rb and ensure machine_translations/
      directory is NOT added to I18n.load_path.
    ERROR
  end

  # Save reference to current backend (human translations from I18n.load_path)
  human_backend = I18n.backend

  # Force load all human translations (backends load lazily by default)
  I18n.load_path.each do |file|
    human_backend.load_translations(file) if File.exist?(file)
  end

  # Load machine translations into a separate backend
  machine_backend = I18n::Backend::Simple.new
  machine_translation_path = Rails.root.join('config', 'machine_translations', '*.yml')

  Dir[machine_translation_path].sort.each do |filepath|
    # Skip source tracking files (src_en_*.yml) - they're metadata, not translations
    next if File.basename(filepath).start_with?('src_en_')

    yaml_data = YAML.load_file(filepath)
    yaml_data.each do |locale, translations|
      machine_backend.store_translations(locale.to_sym, translations)
    end
  end

  # Replace backend with smart fallback: human first, then machine, then English
  I18n.backend = MachineTranslationFallbackBackend.new(human_backend, machine_backend)
end
