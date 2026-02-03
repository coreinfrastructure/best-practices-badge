# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Helper methods for machine translation rake tasks.
# Extracted to a module to keep rake tasks clean and testable.
#
# Metrics cops disabled: this is a rake task helper module where slightly
# longer methods improve readability over excessive decomposition.
# rubocop:disable Rails/Output, Metrics/ModuleLength, Metrics/ClassLength
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
module MachineTranslationHelpers
  # Languages in priority order:
  # French first (reviewer knows some), then German, Japanese, Chinese,
  # Portuguese, Spanish, Russian, and Swahili last (limited LLM support)
  TRANSLATION_PRIORITY = %w[fr de ja zh-CN pt-BR es ru sw].freeze

  # Human-readable language names for prompts
  LANGUAGE_NAMES = {
    'fr' => 'French', 'de' => 'German', 'ja' => 'Japanese',
    'zh-CN' => 'Simplified Chinese', 'pt-BR' => 'Brazilian Portuguese',
    'es' => 'Spanish', 'ru' => 'Russian', 'sw' => 'Swahili'
  }.freeze

  # Default batch size for Copilot translations (balance speed vs accuracy)
  COPILOT_BATCH_SIZE = 20

  class << self
    def validate_locale!(locale)
      return if I18n.available_locales.map(&:to_s).include?(locale)

      raise ArgumentError,
            "Invalid locale: #{locale}. Available: #{I18n.available_locales.join(', ')}"
    end

    def machine_translation_path(locale)
      Rails.root.join('config', 'machine_translations', "#{locale}.yml")
    end

    def find_untranslated_keys(locale)
      english = load_flat_translations('en')
      translated = load_flat_translations(locale)

      english.keys.select do |key|
        value = translated[key]
        value.nil? || value.to_s.strip.empty?
      end
    end

    def next_locale_needing_translation
      TRANSLATION_PRIORITY.find do |locale|
        find_untranslated_keys(locale).any?
      end || TRANSLATION_PRIORITY.first
    end

    def export_keys_for_translation(locale, keys)
      english = load_flat_translations('en')
      output = { locale => {} }

      keys.each do |key|
        set_nested_key(output[locale], key, english[key])
      end

      timestamp = Time.zone.now.strftime('%Y%m%d_%H%M%S')
      filename = "translate_to_#{locale}_#{timestamp}.yml"
      filepath = Rails.root.join('tmp', filename)
      File.write(filepath, yaml_dump(output))
      filepath
    end

    def print_export_instructions(locale, filepath)
      puts "Exported to: #{filepath}"
      puts ''
      puts 'Next steps:'
      puts '1. Translate the values in this file (keys stay in English)'
      puts '2. Run: rake translation:import[LOCALE,PATH_TO_TRANSLATED_FILE]'
      puts ''
      puts 'Translation tips:'
      puts '- Only translate the VALUES, never the keys'
      puts '- Keep template variables like %{name} unchanged' # rubocop:disable Style/FormatStringToken
      puts '- Keep HTML tags like <a href=...> unchanged'
      puts "- Change /en/ paths to /#{locale}/ in URLs"
      puts '- The result MUST use the same keys'
      puts '- The result MUST be syntactically valid YAML'
    end

    def import_translations(locale, file)
      filepath = file.start_with?('/') ? file : Rails.root.join(file)

      unless File.exist?(filepath)
        puts "File not found: #{filepath}"
        return
      end

      translated = YAML.load_file(filepath)
      unless translated.is_a?(Hash) && translated[locale].is_a?(Hash)
        puts "Invalid YAML structure. Expected: { '#{locale}' => { ... } }"
        return
      end

      existing = load_existing_machine_translations(locale)
      deep_merge!(existing[locale], translated[locale])

      machine_file = machine_translation_path(locale)
      File.write(machine_file, yaml_dump(existing))
      puts "Imported #{count_keys(translated[locale])} keys to #{machine_file}"
    end

    def cleanup_machine_translations
      cleaned_total = 0

      TRANSLATION_PRIORITY.each do |locale|
        cleaned = cleanup_locale(locale)
        cleaned_total += cleaned
      end

      puts "Total cleaned: #{cleaned_total} keys"
    end

    def print_status
      puts 'Translation Status:'
      puts '-' * 60

      english_keys = load_flat_translations('en').keys

      TRANSLATION_PRIORITY.each do |locale|
        human = load_flat_translations(locale, human_only: true)
        machine = load_flat_translations(locale, machine_only: true)

        human_count = (human.keys & english_keys).length
        machine_count = (machine.keys & english_keys).length
        missing = english_keys.length - human_count - machine_count

        puts format('%-8<loc>s Human: %4<human>d  Machine: %4<machine>d  Missing: %4<miss>d',
                    loc: locale, human: human_count, machine: machine_count, miss: missing)
      end
    end

    # Copilot integration methods

    def copilot_lock_path
      Rails.root.join('tmp', 'copilot_translation.lock')
    end

    # rubocop:disable Naming/PredicateMethod
    def acquire_copilot_lock
      lockfile = copilot_lock_path

      # Check if lock exists and handle stale locks
      if File.exist?(lockfile)
        age = Time.zone.now - File.mtime(lockfile)
        return false if age <= 1800 # Lock is fresh (< 30 minutes)

        puts "Removing stale lock (#{(age / 60).round} minutes old)"
        FileUtils.rm_f(lockfile)
      end

      File.write(lockfile, "#{Process.pid}\n#{Time.zone.now.iso8601}")
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def release_copilot_lock
      FileUtils.rm_f(copilot_lock_path)
    end

    def language_name(locale)
      LANGUAGE_NAMES[locale] || locale
    end

    # Export source English text paired with target locale structure
    # Returns both full paths (for file operations) and basenames (for prompt)
    def export_for_copilot(locale, keys)
      english = load_flat_translations('en')
      timestamp = Time.zone.now.strftime('%Y%m%d_%H%M%S')
      tmp_dir = Rails.root.join('tmp')

      # Create source file with English text
      source_output = { 'en' => {} }
      keys.each { |key| set_nested_key(source_output['en'], key, english[key]) }
      source_name = "copilot_source_#{locale}_#{timestamp}.yml"
      File.write(tmp_dir.join(source_name), yaml_dump(source_output))

      # Create target file structure (same keys, empty values for guidance)
      target_output = { locale => {} }
      keys.each { |key| set_nested_key(target_output[locale], key, '') }
      target_name = "copilot_target_#{locale}_#{timestamp}.yml"
      File.write(tmp_dir.join(target_name), yaml_dump(target_output))

      {
        source: tmp_dir.join(source_name),      # Full path for file ops
        target: tmp_dir.join(target_name),      # Full path for file ops
        source_name: source_name,               # Basename for prompt
        target_name: target_name,               # Basename for prompt
        timestamp: timestamp
      }
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # source_name and target_name are basenames (not full paths) for security
    def build_copilot_prompt(locale, source_name, target_name)
      lang = language_name(locale)
      # rubocop:disable Style/FormatStringToken
      <<~PROMPT
        You are a professional translator for the OpenSSF Best Practices Badge web application.
        Translate the English YAML file #{source_name} into #{lang}.

        CRITICAL RULES:
        1. Only translate the VALUES, never the YAML keys (keys must stay in English)
        2. Keep template variables like %{name}, %{count} EXACTLY as-is
        3. Keep HTML tags like <a href="...">, <strong>, <em> unchanged
        4. Change /en/ paths in URLs to /#{locale}/ (e.g., /en/projects -> /#{locale}/projects)
        5. Preserve YAML structure exactly - same nesting, same keys
        6. For pluralization keys (zero, one, few, many, other), translate each form appropriately for #{lang}
        7. Proper names like "GitHub" and "OpenSSF" should NOT be translated

        WORKFLOW:
        1. Read the source file: #{source_name}
        2. Translate each value to #{lang}
        3. Write the translated YAML to: #{target_name}
        4. The output file MUST have '#{locale}:' as the root key (not 'en:')
        5. Review your translations for accuracy and natural #{lang} phrasing
        6. Fix any issues you find

        After completing the translation, output ONLY the text "TRANSLATION_COMPLETE" on a line by itself.
      PROMPT
      # rubocop:enable Style/FormatStringToken
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

    def run_copilot_translation(locale, batch_size: COPILOT_BATCH_SIZE)
      missing_keys = find_untranslated_keys(locale)
      if missing_keys.empty?
        puts "No untranslated keys for #{locale}!"
        return { success: true, translated: 0, locale: locale }
      end

      keys_to_translate = missing_keys.first(batch_size)
      puts "Translating #{keys_to_translate.length} keys to #{language_name(locale)}..."

      files = export_for_copilot(locale, keys_to_translate)
      # Use basenames in prompt (copilot runs from tmp/ directory)
      prompt = build_copilot_prompt(locale, files[:source_name], files[:target_name])
      prompt_file = Rails.root.join('tmp', "copilot_prompt_#{locale}_#{files[:timestamp]}.txt")
      File.write(prompt_file, prompt)

      copilot_success = execute_copilot(prompt, files[:target])
      import_success = copilot_success && File.exist?(files[:target]) &&
                       import_copilot_result(locale, files[:target])

      if import_success
        { success: true, translated: keys_to_translate.length, locale: locale }
      else
        puts 'Translation failed. Files preserved for debugging:'
        puts "  Source: #{files[:source]}"
        puts "  Target: #{files[:target]}"
        puts "  Prompt: #{prompt_file}"
        { success: false, translated: 0, locale: locale }
      end
    end

    private

    def load_flat_translations(locale, human_only: false, machine_only: false)
      result = {}

      load_human_translations_into(result, locale) unless machine_only
      load_machine_translations_into(result, locale) unless human_only
      load_english_if_needed(result, locale)

      result
    end

    def load_human_translations_into(result, locale)
      Rails.root.glob("config/locales/*.#{locale}.yml").each do |file|
        merge_flat!(result, YAML.load_file(file)&.dig(locale) || {})
      end

      translation_file = Rails.root.join('config', 'locales', "translation.#{locale}.yml")
      return unless File.exist?(translation_file)

      merge_flat!(result, YAML.load_file(translation_file)&.dig(locale) || {})
    end

    def load_machine_translations_into(result, locale)
      machine_file = machine_translation_path(locale)
      return unless File.exist?(machine_file)

      merge_flat!(result, YAML.load_file(machine_file)&.dig(locale) || {})
    end

    def load_english_if_needed(result, locale)
      return unless locale == 'en'

      en_file = Rails.root.join('config', 'locales', 'en.yml')
      return unless File.exist?(en_file)

      merge_flat!(result, YAML.load_file(en_file)&.dig('en') || {})
    end

    def load_existing_machine_translations(locale)
      machine_file = machine_translation_path(locale)
      existing = File.exist?(machine_file) ? YAML.load_file(machine_file) : {}
      existing ||= {}
      existing[locale] ||= {}
      existing
    end

    def cleanup_locale(locale)
      machine_file = machine_translation_path(locale)
      return 0 unless File.exist?(machine_file)

      machine = YAML.load_file(machine_file)
      return 0 unless machine&.dig(locale)

      human = load_flat_translations(locale, human_only: true)
      original_count = count_keys(machine[locale])

      remove_keys_present_in!(machine[locale], human)

      new_count = count_keys(machine[locale])
      cleaned = original_count - new_count

      return 0 unless cleaned.positive?

      File.write(machine_file, yaml_dump(machine))
      puts "#{locale}: Removed #{cleaned} keys (now #{new_count} machine translations)"
      cleaned
    end

    def merge_flat!(target, source, prefix = '')
      source.each do |key, value|
        full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        if value.is_a?(Hash)
          merge_flat!(target, value, full_key)
        else
          target[full_key] = value
        end
      end
    end

    def set_nested_key(hash, dotted_key, value)
      keys = dotted_key.split('.')
      current = hash
      keys[0..-2].each do |key|
        current[key] ||= {}
        current = current[key]
      end
      current[keys.last] = value
    end

    def count_keys(hash, count = 0)
      return count unless hash.is_a?(Hash)

      hash.each_value do |value|
        count = value.is_a?(Hash) ? count_keys(value, count) : count + 1
      end
      count
    end

    def deep_merge!(target, source)
      source.each do |key, value|
        if value.is_a?(Hash) && target[key].is_a?(Hash)
          deep_merge!(target[key], value)
        else
          target[key] = value
        end
      end
    end

    def remove_keys_present_in!(hash, flat_keys, prefix = '')
      hash.each_key.to_a.each do |key|
        full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        if hash[key].is_a?(Hash)
          remove_keys_present_in!(hash[key], flat_keys, full_key)
          hash.delete(key) if hash[key].empty?
        elsif flat_keys.key?(full_key) && !flat_keys[full_key].to_s.strip.empty?
          hash.delete(key)
        end
      end
    end

    def yaml_dump(data)
      data.to_yaml(line_width: -1)
    end

    # Copilot execution helpers

    # rubocop:disable Naming/PredicateMethod
    def execute_copilot(prompt, target_file)
      # Build copilot command with minimal permissions (read + write only)
      # Runs from tmp/ directory so copilot can only access files there
      cmd = [
        'copilot',
        '-p', prompt,
        '--allow-tool', 'read',
        '--allow-tool', 'write',
        '--silent',
        '--no-ask-user'
      ]

      puts 'Running Copilot translation...'
      # Run from tmp/ directory to restrict file access to only that directory
      result = Dir.chdir(Rails.root.join('tmp')) { system(*cmd) }

      # Check if target file was created/modified
      if result && File.exist?(target_file)
        content = File.read(target_file)
        # Verify it's not empty or just the template
        return content.length > 50 && !content.include?(": ''")
      end

      false
    end
    # rubocop:enable Naming/PredicateMethod

    # Returns true on success, false on failure
    def import_copilot_result(locale, target_file)
      return false unless File.exist?(target_file)

      translated = YAML.load_file(target_file)
      unless translated.is_a?(Hash) && translated[locale].is_a?(Hash)
        puts 'Invalid YAML structure in Copilot output'
        return false
      end

      existing = load_existing_machine_translations(locale)
      deep_merge!(existing[locale], translated[locale])

      machine_file = machine_translation_path(locale)
      File.write(machine_file, yaml_dump(existing))
      puts "Imported #{count_keys(translated[locale])} keys to #{machine_file}"
      true
    rescue Psych::SyntaxError => e
      puts "YAML parse error in Copilot output: #{e.message}"
      false
    end
  end
end
# rubocop:enable Rails/Output, Metrics/ModuleLength, Metrics/ClassLength
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
