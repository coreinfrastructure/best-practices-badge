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

    def source_tracking_path(locale)
      Rails.root.join('config', 'machine_translations', "src_en_#{locale}.yml")
    end

    def find_untranslated_keys(locale)
      english = load_flat_translations('en')
      translated = load_flat_translations(locale)
      human_translated = load_flat_translations(locale, human_only: true)
      source_tracking = load_source_tracking(locale)

      english.keys.select do |key|
        value = translated[key]
        # Key is untranslated if:
        # 1. No translation exists or is empty, OR
        # 2. English source has changed since machine translation (and no human translation)
        next true if value.nil? || value.to_s.strip.empty?
        next false if human_translated.key?(key) # Has human translation - ignore source changes

        # Check if English source has changed since machine translation
        source_tracking.key?(key) && source_tracking[key] != english[key]
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

      result = { filepath: filepath, timestamp: timestamp, keys: keys, locale: locale }

      # Always generate translation examples for consistency (helps both AI and humans)
      examples = generate_translation_examples_files(locale, keys, english, timestamp)
      result[:examples] = examples if examples

      # Generate comprehensive instructions file for translators
      instructions_file = generate_translation_instructions(locale, timestamp, examples)
      result[:instructions] = instructions_file

      result
    end

    # Generate example translation files showing how technical terms were translated
    # Returns hash with file paths and metadata, or nil if no examples available
    def generate_translation_examples_files(locale, keys_to_translate, english, timestamp)
      # Find technical terms in the text to be translated
      technical_terms = extract_technical_terms(keys_to_translate, english)
      return if technical_terms.empty?

      # Find existing translations containing these terms
      example_keys = find_example_translations(locale, technical_terms, english)
      return if example_keys.empty?

      # Limit examples to avoid overwhelming translators (max 15 examples)
      example_keys = example_keys.take(15)

      tmp_dir = Rails.root.join('tmp')

      # Create example source file (English)
      example_source = { 'en' => {} }
      example_keys.each { |key| set_nested_key(example_source['en'], key, english[key]) }
      example_source_name = "examples_en_#{locale}_#{timestamp}.yml"
      en_filepath = tmp_dir.join(example_source_name)
      File.write(en_filepath, yaml_dump(example_source))

      # Create example target file (existing translations)
      existing_translations = load_flat_translations(locale)
      example_target = { locale => {} }
      example_keys.each do |key|
        set_nested_key(example_target[locale], key, existing_translations[key])
      end
      example_target_name = "examples_#{locale}_#{timestamp}.yml"
      locale_filepath = tmp_dir.join(example_target_name)
      File.write(locale_filepath, yaml_dump(example_target))

      puts "Generated #{example_keys.length} translation examples for #{language_name(locale)}"
      {
        en_filepath: en_filepath,
        locale_filepath: locale_filepath,
        source_name: example_source_name,
        target_name: example_target_name,
        term_count: technical_terms.length,
        example_count: example_keys.length
      }
    end

    # Generate comprehensive translation instructions file
    # Returns filepath to instructions
    def generate_translation_instructions(locale, timestamp, examples)
      lang = language_name(locale)
      tmp_dir = Rails.root.join('tmp')
      instructions_file = tmp_dir.join("TRANSLATION_INSTRUCTIONS_#{locale}_#{timestamp}.txt")

      examples_section =
        if examples
          <<~EXAMPLES

            TRANSLATION EXAMPLES:
            Review these example translations for consistent terminology:
            - English examples: #{File.basename(examples[:en_filepath])}
            - #{lang} translations: #{File.basename(examples[:locale_filepath])}

            These show how #{examples[:term_count]} technical terms have been
            translated previously. Use the same translations for the same terms
            to maintain consistency across the application.
          EXAMPLES
        else
          ''
        end

      instructions = <<~INSTRUCTIONS
        TRANSLATION INSTRUCTIONS FOR #{lang.upcase}
        ========================================

        Project: OpenSSF Best Practices Badge web application
        Target Language: #{lang}
        Locale Code: #{locale}
        #{examples_section}
        CRITICAL RULES:
        ---------------

        1. Only translate the VALUES, never the YAML keys (keys stay exactly the same and in English)

        2. Keep template variables in form %{some_name} EXACTLY as-is
           - These are placeholders that will be filled in at runtime
           - Do NOT translate the variable names
           - Do NOT change the format
           - Example: "The URL is %{project_info_url}"
           - Correct: Translate text but keep %{project_info_url} unchanged
           - WRONG: Changing %{project_info_url} will fail validation

        3. Keep HTML tags unchanged
           - Tags like <a href="...">, <strong>, <em> must stay as-is
           - Only translate the text between tags

        4. Change /en/ paths to /#{locale}/ in URLs
           - Example: /en/projects becomes /#{locale}/projects

        5. Preserve YAML structure exactly
           - Same nesting level, same keys, same indentation
           - One exception: At the top level, the locale will #{locale}

        6. For pluralization keys (zero, one, few, many, other)
           - Translate each form appropriately for #{lang}

        7. Proper names should NOT be translated in general
           - GitHub, OpenSSF, Scorecard, etc. stay as-is

        YAML FORMATTING:
        ----------------

        - Use DOUBLE QUOTES (") for string values, NOT single quotes (')
        - Single quotes require escaping apostrophes as '', causing errors
        - Double quotes handle apostrophes, colons, and special characters
        - To include double quotes inside strings, use backslash: \\"
        - Example CORRECT: description: "We're sorry you can't continue"
        - Example WRONG: description: 'We're sorry' (breaks YAML)

        VALIDATION:
        -----------

        Your translation will be automatically validated for:
        - Correct keys (must match source exactly)
        - Preserved placeholders (%{name} must appear exactly as in source)
        - Non-empty values (unless source is empty)
        - Valid YAML syntax

        Translations that fail validation will be rejected.

        WORKFLOW:
        ---------

        1. Review the example files (if provided) for terminology consistency
        2. Translate the values in the YAML file to be translated
        3. Review each translated value to ensure they are accurate, clear,
           conventional for the #{locale} (not a word-by-word translation).
        4. The result MUST use the same keys
        5. The result MUST be syntactically valid YAML

        Import with: rake translation:import[#{locale},PATH_TO_TRANSLATED_FILE]
      INSTRUCTIONS

      File.write(instructions_file, instructions)
      instructions_file
    end

    def print_export_instructions(locale, filepath, examples = nil, instructions = nil)
      puts "YAML file to be translated has been exported to: #{filepath}"

      if instructions
        puts "Translation instructions: #{instructions}"
        puts ''
      end

      if examples
        puts 'Translation examples:'
        puts "  English: #{examples[:en_filepath]}"
        puts "  #{language_name(locale)}: #{examples[:locale_filepath]}"
        puts "  (#{examples[:term_count]} technical terms with existing translations)"
      end

      puts ''
      puts 'Next steps:'
      puts ''
      if instructions
        puts '* Read the translation instructions file for detailed guidance'
      end
      if examples
        puts '* Review the example files for consistent terminology'
      end
      puts '* Translate the values in the YAML file to be translated (keys stay exactly the same and in English)'
      puts '* Import with: rake translation:import[LOCALE,PATH_TO_TRANSLATED_FILE]'
    end

    # Import translated YAML file with validation and source tracking
    # Returns true on success, false on failure
    # Automatically repairs common YAML formatting issues (helps both AI and humans)
    # rubocop:disable Naming/PredicateMethod
    def import_translations(locale, file, expected_keys: nil)
      filepath = file.start_with?('/') ? file : Rails.root.join(file)

      unless File.exist?(filepath)
        puts "File not found: #{filepath}"
        return false
      end

      # Load YAML with automatic repair for common issues
      translated = load_yaml_with_fallback(filepath, locale)
      return false unless translated

      unless translated.is_a?(Hash) && translated[locale].is_a?(Hash)
        puts "Invalid YAML structure. Expected: { '#{locale}' => { ... } }"
        return false
      end

      # Write back repaired YAML if it was fixed
      File.write(filepath, yaml_dump(translated))

      # Always validate against English keys
      english = load_flat_translations('en')
      validation_keys = expected_keys || english.keys
      translated[locale] = validate_and_filter_keys(
        translated[locale], validation_keys, locale
      )

      if translated[locale].empty?
        puts 'No valid keys to import after validation'
        return false
      end

      existing = load_existing_machine_translations(locale)
      deep_merge!(existing[locale], translated[locale])

      machine_file = machine_translation_path(locale)
      File.write(machine_file, yaml_dump(existing))
      puts "Imported #{count_keys(translated[locale])} keys to #{machine_file}"

      # Always track source English text for stale translation detection
      update_source_tracking(locale, translated[locale])

      true
    end
    # rubocop:enable Naming/PredicateMethod

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

    # Copilot-specific: Create empty target file for Copilot to fill
    # Copilot needs an empty structure showing what keys to translate
    def export_for_copilot(locale, keys)
      # Use generic export which creates source file and examples
      export_result = export_keys_for_translation(locale, keys)

      # Create empty target file with just the key structure for Copilot
      tmp_dir = Rails.root.join('tmp')
      timestamp = export_result[:timestamp]
      target_output = { locale => {} }
      keys.each { |key| set_nested_key(target_output[locale], key, '') }
      target_name = "copilot_target_#{locale}_#{timestamp}.yml"
      target_file = tmp_dir.join(target_name)
      File.write(target_file, yaml_dump(target_output))

      # Return combined result for Copilot
      {
        source: export_result[:filepath],         # Source English text
        target: target_file,                      # Empty target structure
        source_name: File.basename(export_result[:filepath]),
        target_name: target_name,
        instructions: export_result[:instructions], # Instructions file
        instructions_name: File.basename(export_result[:instructions]),
        examples: export_result[:examples], # May be nil
        timestamp: timestamp,
        keys: keys
      }
    end

    # Extract technical terms from English text that should use consistent translation
    def extract_technical_terms(keys, english)
      terms = Set.new
      keys.each do |key|
        text = english[key].to_s
        next if text.empty?

        # Pattern 1: Acronyms (2+ consecutive capitals, possibly with slashes)
        text.scan(%r{\b[A-Z]{2,}(?:/[A-Z]+)*\b}) { |match| terms << match }

        # Pattern 2: Proper nouns (capitalized words, excluding sentence starts)
        text.scan(/(?<!^|\. )\b[A-Z][a-z]+(?:[A-Z][a-z]+)*\b/) { |match| terms << match }

        # Pattern 3: Technical compounds (hyphenated terms)
        text.scan(/\b[a-z]+-[a-z]+(?:-[a-z]+)*\b/i) { |match| terms << match }

        # Pattern 4: Long technical words (12+ characters)
        text.scan(/\b[a-z]{12,}\b/i) { |match| terms << match }
      end
      terms.to_a
    end

    # Find existing translations that contain the technical terms
    def find_example_translations(locale, terms, english)
      return [] if terms.empty?

      existing_translations = load_flat_translations(locale)
      human_translations = load_flat_translations(locale, human_only: true)

      example_keys = []
      terms.each do |term|
        # Find keys where English contains this term
        matching_keys =
          english.keys.select do |key|
            text = english[key].to_s
            text.include?(term) && human_translations.key?(key) &&
              !existing_translations[key].to_s.strip.empty?
          end

        # Add first match for this term (if any)
        example_keys << matching_keys.first if matching_keys.any?
      end

      example_keys.compact.uniq
    end

    # Copilot-specific: Build prompt that references the instructions file
    def build_copilot_prompt(locale, source_name, target_name, instructions_name)
      lang = language_name(locale)

      <<~PROMPT
        You are a professional translator for the OpenSSF Best Practices Badge web application.

        TASK: Translate the English YAML file #{source_name} into #{lang}.

        INSTRUCTIONS: Read #{instructions_name} for complete translation guidelines.

        KEY POINTS:
        - Only translate VALUES, never keys
        - Keep every %{variable} exactly as-is
        - Keep HTML tags unchanged
        - Use DOUBLE QUOTES for strings
        - Output to: #{target_name}
        - Root key must be '#{locale}:' (not 'en:')

        Your translation will be automatically validated for correct keys,
        preserved placeholders, and valid YAML syntax.

        After completing the translation, output ONLY the text "TRANSLATION_COMPLETE" on a line by itself.
      PROMPT
    end

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
      prompt = build_copilot_prompt(
        locale,
        files[:source_name],
        files[:target_name],
        files[:instructions_name]
      )
      prompt_file = Rails.root.join('tmp', "copilot_prompt_#{locale}_#{files[:timestamp]}.txt")
      File.write(prompt_file, prompt)

      copilot_success = execute_copilot(prompt, files[:target])
      import_success = copilot_success && File.exist?(files[:target]) &&
                       import_translations(locale, files[:target], expected_keys: keys_to_translate)

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

    # rubocop:disable Metrics/CyclomaticComplexity
    def cleanup_locale(locale)
      machine_file = machine_translation_path(locale)
      source_file = source_tracking_path(locale)
      return 0 unless File.exist?(machine_file)

      machine = YAML.load_file(machine_file)
      return 0 unless machine&.dig(locale)

      human = load_flat_translations(locale, human_only: true)
      original_count = count_keys(machine[locale])

      remove_keys_present_in!(machine[locale], human)

      new_count = count_keys(machine[locale])
      cleaned = original_count - new_count

      if cleaned.positive?
        File.write(machine_file, yaml_dump(machine))
        puts "#{locale}: Removed #{cleaned} keys (now #{new_count} machine translations)"

        # Also clean up source tracking
        if File.exist?(source_file)
          source = YAML.load_file(source_file)
          if source&.dig('en')
            remove_keys_present_in!(source['en'], human)
            File.write(source_file, yaml_dump(source))
          end
        end
      end

      cleaned
    end
    # rubocop:enable Metrics/CyclomaticComplexity

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

    # Load the source tracking file (English text that was translated)
    def load_source_tracking(locale)
      source_file = source_tracking_path(locale)
      return {} unless File.exist?(source_file)

      data = YAML.load_file(source_file)
      return {} unless data.is_a?(Hash) && data['en'].is_a?(Hash)

      result = {}
      merge_flat!(result, data['en'])
      result
    end

    # Update source tracking with current English text for translated keys
    def update_source_tracking(locale, translated_nested)
      english = load_flat_translations('en')
      translated_flat = {}
      merge_flat!(translated_flat, translated_nested)

      # Load existing source tracking
      source_file = source_tracking_path(locale)
      existing =
        if File.exist?(source_file)
          YAML.load_file(source_file) || {}
        else
          {}
        end
      existing['en'] ||= {}

      # For each translated key, store the current English text
      translated_flat.each_key do |key|
        next unless english.key?(key)

        set_nested_key(existing['en'], key, english[key])
      end

      File.write(source_file, yaml_dump(existing))
      puts "Updated source tracking: #{source_file}"
    end

    # Validate that translated keys match expected keys, filtering out extras
    # Returns filtered nested hash with only expected keys
    def validate_and_filter_keys(translated_nested, expected_keys, _locale)
      translated_flat = {}
      merge_flat!(translated_flat, translated_nested)

      report_unexpected_keys(translated_flat.keys, expected_keys)
      report_missing_keys(expected_keys, translated_flat.keys)

      build_filtered_translations(expected_keys, translated_flat)
    end

    def report_unexpected_keys(translated_keys, expected_keys)
      unexpected_keys = translated_keys - expected_keys
      return if unexpected_keys.none?

      puts "Warning: Found #{unexpected_keys.length} unexpected keys in translation:"
      unexpected_keys.first(10).each { |key| puts "  - #{key}" }
      puts "  ... and #{unexpected_keys.length - 10} more" if unexpected_keys.length > 10
      puts 'These keys were not in the original export and will be removed.'
    end

    def report_missing_keys(expected_keys, translated_keys)
      missing_keys = expected_keys - translated_keys
      return if missing_keys.none?

      puts "Note: #{missing_keys.length} keys were not translated (skipped)"
    end

    def build_filtered_translations(expected_keys, translated_flat)
      english = load_flat_translations('en')
      filtered = {}
      invalid_placeholders = []

      expected_keys.each do |key|
        next unless translated_flat.key?(key)

        value = translated_flat[key]
        next if value.nil? || value.to_s.strip.empty?

        unless valid_placeholders?(english[key], value)
          invalid_placeholders << key
          next
        end

        set_nested_key(filtered, key, value)
      end

      report_invalid_placeholders(invalid_placeholders)
      filtered
    end

    def report_invalid_placeholders(invalid_placeholders)
      return if invalid_placeholders.none?

      puts "Warning: #{invalid_placeholders.length} translations have invalid placeholders:"
      invalid_placeholders.first(10).each { |key| puts "  - #{key}" }
      puts "  ... and #{invalid_placeholders.length - 10} more" if invalid_placeholders.length > 10
      puts 'Placeholders like %<name>s must appear exactly as in source.'
    end

    # Check if translation preserves all placeholders from source
    # Placeholders are in format %{variable_name}
    def valid_placeholders?(source_text, translated_text)
      return true if source_text.nil? || translated_text.nil?

      source_placeholders = extract_placeholders(source_text.to_s)
      translated_placeholders = extract_placeholders(translated_text.to_s)

      # All source placeholders must appear in translation
      source_placeholders.all? { |ph| translated_placeholders.include?(ph) }
    end

    # Extract all placeholder variables from text
    # Returns array of placeholder strings like ["%{name}", "%{count}"]
    def extract_placeholders(text)
      text.scan(/%\{[A-Za-z0-9_]+\}/)
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

    # Load YAML file, attempting to fix common issues if normal parsing fails
    def load_yaml_with_fallback(file, locale)
      # First try: load normally
      begin
        return YAML.load_file(file)
      rescue Psych::SyntaxError => e
        puts "Initial YAML parse failed: #{e.message}"
        puts 'Attempting to repair YAML formatting...'
      end

      # Second try: fix common quoting issues
      content = File.read(file)
      fixed_content = fix_yaml_quoting(content, locale)

      begin
        translated = YAML.load(fixed_content)
        puts 'Successfully repaired YAML formatting'
        # Write the fixed version back
        File.write(file, fixed_content)
        return translated
      rescue Psych::SyntaxError => e
        puts "YAML parse error after repair attempt: #{e.message}"
        return
      end
    end

    # Fix common YAML quoting issues in Copilot output
    def fix_yaml_quoting(content, _locale)
      lines = content.split("\n")
      fixed_lines =
        lines.map do |line|
          # Match lines with single-quoted values
          # Pattern: key: 'value...'
          if line =~ /^(\s+)(\w+):\s+'(.+)'$/
            indent = ::Regexp.last_match(1)
            key = ::Regexp.last_match(2)
            value = ::Regexp.last_match(3)

            # Check if value contains an unescaped apostrophe
            # In YAML single quotes, apostrophes should be doubled ('')
            if value.include?("'") && !value.include?("''")
              # Convert to double quotes and escape any existing double quotes
              escaped_value = value.gsub('"', '\"')
              "#{indent}#{key}: \"#{escaped_value}\""
            else
              # Single quotes are fine if no apostrophes
              line
            end
          else
            line
          end
        end
      fixed_lines.join("\n")
    end
  end
end
# rubocop:enable Rails/Output, Metrics/ModuleLength, Metrics/ClassLength
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
