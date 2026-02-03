# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Rake tasks for machine translation workflow.
#
# These tasks help manage machine translations that fill gaps where human
# translations aren't yet available. The workflow is:
#
# 1. Export untranslated keys: rake translation:export[fr,50]
# 2. Translate that file using any tool (Copilot, ChatGPT, human, etc.)
# 3. Import the translated file: rake translation:import[fr,tmp/file.yml]
# 4. Periodically clean up: rake translation:cleanup
#
# Human translations always take precedence over machine translations.

require_relative 'machine_translation_helpers'

# rubocop:disable Metrics/BlockLength
namespace :translation do
  desc 'List untranslated keys for a locale (e.g., rake translation:untranslated[fr])'
  task :untranslated, [:locale] => :environment do |_t, args|
    locale = args[:locale] || 'fr'
    MachineTranslationHelpers.validate_locale!(locale)

    missing = MachineTranslationHelpers.find_untranslated_keys(locale)
    puts "Found #{missing.length} untranslated keys for #{locale}:"
    missing.first(20).each { |key| puts "  #{key}" }
    puts "  ... and #{missing.length - 20} more" if missing.length > 20
  end

  desc 'Export untranslated keys to YAML for translation'
  task :export, %i[locale count] => :environment do |_t, args|
    locale = args[:locale] || MachineTranslationHelpers.next_locale_needing_translation
    count = (args[:count] || 50).to_i
    MachineTranslationHelpers.validate_locale!(locale)

    missing_keys = MachineTranslationHelpers.find_untranslated_keys(locale)
    if missing_keys.empty?
      puts "No untranslated keys for #{locale}!"
      next
    end

    result = MachineTranslationHelpers.export_keys_for_translation(
      locale, missing_keys.first(count)
    )
    MachineTranslationHelpers.print_export_instructions(
      locale, result[:filepath], result[:examples], result[:instructions]
    )
  end

  desc 'Import translated YAML into machine_translations'
  task :import, %i[locale file] => :environment do |_t, args|
    locale = args[:locale]
    file = args[:file]

    unless locale && file
      puts 'Usage: rake translation:import[LOCALE,FILE]'
      puts 'Example: rake translation:import[fr,tmp/translate_to_fr_20240101.yml]'
      next
    end

    MachineTranslationHelpers.validate_locale!(locale)
    MachineTranslationHelpers.import_translations(locale, file)
  end

  desc 'Remove machine translations that have human versions'
  task cleanup: :environment do
    MachineTranslationHelpers.cleanup_machine_translations
  end

  desc 'Show translation status for all locales'
  task status: :environment do
    MachineTranslationHelpers.print_status
  end

  desc 'Run automated translation via GitHub Copilot (safe for cron/timer)'
  task :copilot, %i[locale count] => :environment do |_t, args|
    unless MachineTranslationHelpers.acquire_copilot_lock
      puts 'Another Copilot translation is in progress. Skipping.'
      next
    end

    begin
      locale = args[:locale] || MachineTranslationHelpers.next_locale_needing_translation
      count = (args[:count] || MachineTranslationHelpers::COPILOT_BATCH_SIZE).to_i
      MachineTranslationHelpers.validate_locale!(locale)

      result = MachineTranslationHelpers.run_copilot_translation(locale, batch_size: count)

      if result[:success]
        puts "Successfully translated #{result[:translated]} keys for #{result[:locale]}"
        MachineTranslationHelpers.print_status
      else
        puts 'Translation failed. Check logs for details.'
        exit 1
      end
    ensure
      MachineTranslationHelpers.release_copilot_lock
    end
  end
end
# rubocop:enable Metrics/BlockLength
