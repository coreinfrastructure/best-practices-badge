# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Custom I18n backend with single merged hash for O(1) translation lookup.
#
# CRITICAL REQUIREMENT:
# Machine translations MUST NOT be in I18n.load_path because translation.io
# reads from I18n.load_path and would sync them to the remote service.
# This is not a *security* requirement, but it is needed for correct data.
#
# Translation precedence (highest to lowest):
# 1. Human translations (from I18n.load_path)
# 2. Machine translations (from config/machine_translations/)
# 3. English fallback
#
# For pluralization hashes, merging happens at the key level
# (:one, :other, etc.) so partial human translations are filled
# in by machine translations.
#
# PERFORMANCE: Single hash lookup per translation. All values frozen at init.

# rubocop:disable Style/Send, Metrics/ClassLength
class MachineTranslationFallbackBackend < I18n::Backend::Simple
  # Pluralization keys used by I18n to select singular/plural forms.
  PLURAL_KEYS = %i[zero one two few many other].freeze

  # Initialize the backend and build the merged translation hash.
  # @param human_backend [I18n::Backend::Simple] backend human translations
  # @param machine_backend [I18n::Backend::Simple] backend machine translations
  def initialize(human_backend, machine_backend)
    super()
    @human_backend = human_backend
    @translations = build_merged_hash(
      human_backend.send(:translations),
      machine_backend.send(:translations)
    )
  end

  # Look up a translation with single hash lookup.
  # @param locale [Symbol] the locale (e.g., :fr, :de)
  # @param key [String, Symbol] the translation key
  # @param options [Hash] options including :scope, :count, :default
  # @return [String, Hash, Object] the translated value
  # rubocop:disable Style/OptionHash
  def translate(locale, key, options = {})
    lookup_key = build_lookup_key(key, options[:scope])
    value = @translations.dig(locale, lookup_key)

    return process_translation(locale, lookup_key, value, options) if value

    # Key not found - let human backend handle missing translation
    @human_backend.translate(locale, key, options)
  end
  # rubocop:enable Style/OptionHash

  # Return all available locales.
  # @return [Array<Symbol>] available locales
  def available_locales
    @translations.keys
  end

  # No-op: translations are loaded once at startup and remain constant.
  def reload!; end

  # Eagerly load translations in the human backend.
  def eager_load!
    @human_backend.eager_load! if @human_backend.respond_to?(:eager_load!)
  end

  # Return the nested translations hash from the human backend.
  # @return [Hash] nested translations hash keyed by locale
  def translations
    @human_backend.send(:translations)
  end

  private

  # Build a single merged hash: machine base → human overlay → English fallback.
  # @param human [Hash] nested human translations {locale: {key: value}}
  # @param machine [Hash] nested machine translations
  # @return [Hash] frozen flat hash {locale: {"dotted.key" => value}}
  def build_merged_hash(human, machine)
    human_flat = flatten_all(human)
    machine_flat = flatten_all(machine)
    english = human_flat[:en] || {}

    result = {}
    (human_flat.keys | machine_flat.keys).each do |locale|
      result[locale] = merge_locale(
        human_flat[locale] || {},
        machine_flat[locale] || {},
        locale == :en ? {} : english
      ).freeze
    end
    result.freeze
  end

  # Flatten all locales from nested to dotted-key format.
  # @param nested [Hash] nested translations
  # @return [Hash] {locale: {"dotted.key" => value}}
  def flatten_all(nested)
    result = {}
    nested.each { |locale, tree| result[locale] = flatten_tree(tree, '') }
    result
  end

  # Recursively flatten a nested hash into dotted-key format.
  # @param hash [Hash] the hash to flatten
  # @param prefix [String] the key prefix built up during recursion
  # @return [Hash] flat hash with dotted string keys
  def flatten_tree(hash, prefix)
    hash.each_with_object({}) do |(key, value), result|
      full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      if value.is_a?(Hash) && !pluralization_hash?(value)
        result.merge!(flatten_tree(value, full_key))
      else
        result[full_key] = value
      end
    end
  end

  # Merge translations for one locale: machine base → human overlay → English fallback.
  # @param human [Hash] flat human translations for this locale
  # @param machine [Hash] flat machine translations for this locale
  # @param english [Hash] flat English translations (fallback)
  # @return [Hash] merged translations
  def merge_locale(human, machine, english)
    all_keys = (english.keys | machine.keys | human.keys)
    result = {}

    all_keys.each do |key|
      merged = merge_value(human[key], machine[key], english[key])
      result[key] = freeze_value(merged) if present_value?(merged)
    end
    result
  end

  # Merge a single value with precedence: human → machine → english.
  # For pluralization hashes, merges at the key level.
  # @param human [String, Hash, nil] human translation
  # @param machine [String, Hash, nil] machine translation
  # @param english [String, Hash, nil] English fallback
  # @return [String, Hash, nil] merged value
  def merge_value(human, machine, english)
    sources = [english, machine, human].compact
    return if sources.empty?

    # If any source is a pluralization hash, merge at key level
    return merge_pluralization(human, machine, english) if sources.any? { |s| pluralization_hash?(s) }

    # Simple values: return first present value (human > machine > english)
    return human if present_string?(human)
    return machine if present_string?(machine)

    english
  end

  # Merge pluralization hashes at the key level (:one, :other, etc.).
  # @param human [Hash, nil] human pluralization hash
  # @param machine [Hash, nil] machine pluralization hash
  # @param english [Hash, nil] English pluralization hash
  # @return [Hash, nil] merged pluralization hash
  def merge_pluralization(human, machine, english)
    result = {}
    PLURAL_KEYS.each do |pk|
      h = human.is_a?(Hash) ? human[pk] : nil
      m = machine.is_a?(Hash) ? machine[pk] : nil
      e = english.is_a?(Hash) ? english[pk] : nil

      # Precedence: human > machine > english
      value = pick_present(h, m, e)
      result[pk] = value if present_string?(value)
    end
    result.empty? ? nil : result
  end

  # Return first present string value from arguments.
  # @param values [Array<String, nil>] values in precedence order
  # @return [String, nil] first present value or nil
  def pick_present(*values)
    values.find { |v| present_string?(v) }
  end

  # Check if a hash is a pluralization hash (contains :one, :other, etc.).
  # @param value [Object] the value to check
  # @return [Boolean] true if hash contains pluralization keys
  def pluralization_hash?(value)
    value.is_a?(Hash) && PLURAL_KEYS.any? { |k| value.key?(k) }
  end

  # Recursively freeze a value and all nested values.
  # @param value [Object] the value to freeze
  # @return [Object] the frozen value
  def freeze_value(value)
    if value.is_a?(Hash)
      return value.transform_values { |v| freeze_value(v) }
                  .freeze
    end

    value.freeze
  end

  # Build the lookup key by combining scope and key.
  # @param key [String, Symbol] the translation key
  # @param scope [Symbol, String, Array, nil] optional scope prefix
  # @return [String] the full dotted lookup key
  def build_lookup_key(key, scope)
    return key.to_s if scope.nil?

    scope_str = scope.is_a?(Array) ? scope.join('.') : scope.to_s
    "#{scope_str}.#{key}"
  end

  # Check if a string value is present (non-nil, non-empty).
  # @param value [String, nil] the value to check
  # @return [Boolean] true if present
  def present_string?(value)
    value.is_a?(String) ? value != '' : !value.nil?
  end

  # Check if a value is present (non-nil, non-empty).
  # For hashes, checks if any value is present.
  # @param value [Object] the value to check
  # @return [Boolean] true if value is present and usable
  def present_value?(value)
    return false if value.nil?
    return value.each_value.any? { |v| present_string?(v) } if value.is_a?(Hash)

    value != ''
  end

  # Process a found translation: resolve, pluralize, and interpolate.
  # @param locale [Symbol] the locale for pluralization rules
  # @param key [String] the translation key
  # @param value [String, Hash] the raw translation value
  # @param options [Hash] options including :count for pluralization
  # @return [String] the processed translation string
  def process_translation(locale, key, value, options)
    entry = resolve(locale, key, value, options.except(:default))
    return entry if entry.is_a?(::I18n::MissingTranslation)

    entry = pluralize(locale, entry, options[:count]) if options.key?(:count)
    interpolate(locale, entry, options)
  end
end
# rubocop:enable Style/Send, Metrics/ClassLength
