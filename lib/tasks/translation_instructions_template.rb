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
      CRITICAL RULES:
      1. Only translate VALUES, never YAML keys
      2. Keep %<variables>s EXACTLY as-is (placeholders)
      3. Keep HTML tags unchanged
      4. Change /en/ paths to /#{locale}/ in URLs
      5. Preserve YAML structure (same nesting, keys, indentation)
      6. Translate pluralization (zero/one/few/many/other) appropriately
      7. Don't translate proper names (GitHub, OpenSSF, etc.)

      YAML FORMATTING:
      - Use DOUBLE QUOTES for strings (not single quotes)
      - Correct: "We're sorry"
      - Wrong: 'We're sorry' (breaks YAML)

      VALIDATION:
      Your translation will be validated for:
      - Correct keys, preserved placeholders, valid YAML

      WORKFLOW:
      1. Review examples (if provided)
      2. Translate values accurately and naturally for #{lang}
      3. Import: rake translation:import[#{locale},PATH]
    INSTRUCTIONS
  end
  # rubocop:enable Metrics/MethodLength
end
