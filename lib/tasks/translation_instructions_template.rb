# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Template for translation instructions
module TranslationInstructionsTemplate
  # rubocop:disable Metrics/MethodLength
  def self.generate(locale:, lang:, examples: nil)
    examples_text =
      if examples
        en_file = File.basename(examples[:en_filepath])
        locale_file = File.basename(examples[:locale_filepath])
        "\nTRANSLATION EXAMPLES:\n" \
          "- English: #{en_file}\n" \
          "- #{lang}: #{locale_file}\n" \
          "(#{examples[:term_count]} technical terms with existing translations)\n"
      else
        ''
      end

    <<~INSTRUCTIONS
      TRANSLATION INSTRUCTIONS FOR #{lang.upcase}
      ========================================

      Project: OpenSSF Best Practices Badge
      Target: #{lang} (#{locale})
      #{examples_text}
      FILE FORMAT:
      - Source file has 'en:' as root key with English values
      - You MUST change 'en:' to '#{locale}:' at the top
      - Then translate all VALUES to #{lang}
      - Keep all keys unchanged (in English)

      CRITICAL RULES:
      1. Change root YAML key from 'en:' to '#{locale}:'
      2. Only translate VALUES, never YAML keys
      3. Keep %<variables>s EXACTLY as-is (placeholders)
      4. Keep HTML tags unchanged
      5. Change /en/ paths to /#{locale}/ in URLs
      6. Preserve YAML structure (same nesting, keys, indentation)
      7. Translate pluralization (zero/one/few/many/other) appropriately
      8. Don't translate proper names (GitHub, OpenSSF, etc.)
      9. The translation must not be blank unlesss the source is blank

      YAML FORMATTING:
      - Use DOUBLE QUOTES for strings (not single quotes)
      - Correct: "We're sorry"
      - Wrong: 'We're sorry' (breaks YAML)

      VALIDATION:
      Your translation will be validated for:
      - Correct keys, preserved placeholders, valid YAML
      - HTML tags preserved, URL count matches

      WORKFLOW:
      1. Review examples (if provided) to understand style
      2. Change 'en:' to '#{locale}:' in the resulting file
      3. Translate values accurately and naturally for #{lang}

      We can later import them with rake translation:import[#{locale},PATH]
    INSTRUCTIONS
  end
  # rubocop:enable Metrics/MethodLength
end
