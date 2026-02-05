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
# Memory: Only stores merged flat hash; source data is discarded after merge.

# rubocop:disable Style/Send, Metrics/ClassLength
class MachineTranslationFallbackBackend < I18n::Backend::Simple
  # Pluralization keys used by I18n to select singular/plural forms.
  PLURAL_KEYS = %i[zero one two few many other].freeze

  # Initialize the backend by loading and merging translations from files.
  # After building the merged hash, source data is discarded for GC.
  # @param human_files [Array<String>] paths to human translation YAML files
  # @param machine_files [Array<String>] paths to machine translation YAML files
  def initialize(human_files, machine_files)
    super()
    human_nested = load_yaml_files(human_files)
    machine_nested = load_yaml_files(machine_files)
    @translations = build_merged_hash(human_nested, machine_nested)
    # Tell parent class we're initialized (prevents lazy reload in lookup)
    @initialized = true
    # human_nested and machine_nested go out of scope and are GC'd
  end

  # Look up a translation with single hash lookup.
  # @param locale [Symbol] the locale (e.g., :fr, :de)
  # @param key [String, Symbol] the translation key
  # @param options [Hash] options including :scope, :count, :default
  # @return [String, Hash, nil] the translated value or nil if not found
  # rubocop:disable Style/OptionHash
  def translate(locale, key, options = {})
    lookup_key = build_lookup_key(key, options[:scope])
    
    # Special case: empty key means root of all translations
    return extract_subtree(locale, '') if lookup_key.empty?
    
    value = @translations.dig(locale, lookup_key)

    return process_translation(locale, lookup_key, value, options) if value

    # Check if this is a subtree lookup (partial key with children)
    subtree = extract_subtree(locale, lookup_key)
    return subtree if subtree

    # Special case: i18n.plural.rule is needed for pluralization
    # but not in our translation files. Use default English rule.
    return default_plural_rule(locale) if lookup_key == 'i18n.plural.rule'

    # Key not found - handle default using parent's method
    # Don't pass :default to avoid infinite recursion
    default(locale, key, options[:default], options.except(:default))
  end
  # rubocop:enable Style/OptionHash

  # Check if a translation exists.
  # @param locale [Symbol] the locale
  # @param key [String, Symbol] the translation key
  # @param options [Hash] options including :scope
  # @return [Boolean] true if the translation exists
  # rubocop:disable Style/OptionHash
  def exists?(locale, key, options = {})
    lookup_key = build_lookup_key(key, options[:scope])
    return true if @translations.dig(locale, lookup_key)

    # Check if subtree exists
    extract_subtree(locale, lookup_key).present?
  end
  # rubocop:enable Style/OptionHash

  # Return all available locales.
  # @return [Array<Symbol>] available locales
  def available_locales
    @translations.keys
  end

  # No-op: translations are loaded once at startup and remain constant.
  def reload!; end

  # No-op: all translations are loaded at initialization.
  def eager_load!; end

  # Override store_translations to prevent data corruption.
  # This backend uses flat dotted-key format, not nested hashes like Simple.
  # All translations are loaded at initialization; dynamic additions are ignored.
  # rubocop:disable Style/OptionHash
  def store_translations(locale, data, _options = {})
    caller_location = caller.find { |l| !l.include?('/gems/') } || caller(1..1).first
    Rails.logger.warn(
      'MachineTranslationFallbackBackend: ignoring store_translations ' \
      "(locale: #{locale}, keys: #{data.is_a?(Hash) ? data.keys.first(3).inspect : data.class}) " \
      "from #{caller_location}"
    )
  end
  # rubocop:enable Style/OptionHash

  # Return the merged flat translations hash.
  # Note: This returns flat format {"dotted.key" => value}, not nested.
  # @return [Hash] flat translations hash keyed by locale
  attr_reader :translations

  private

  # Load translations from YAML files into a nested hash.
  # @param files [Array<String>] paths to YAML files
  # @return [Hash] nested translations {locale: {key: value}}
  def load_yaml_files(files)
    result = {}
    files.each do |filepath|
      next unless File.exist?(filepath)

      yaml_data = YAML.load_file(filepath)
      next unless yaml_data.is_a?(Hash)

      yaml_data.each do |locale, translations|
        locale_sym = locale.to_sym
        result[locale_sym] ||= {}
        deep_merge!(result[locale_sym], translations) if translations.is_a?(Hash)
      end
    end
    result
  end

  # Deep merge source hash into target hash (mutates target).
  # @param target [Hash] hash to merge into
  # @param source [Hash] hash to merge from
  def deep_merge!(target, source)
    source.each do |key, value|
      if value.is_a?(Hash) && target[key].is_a?(Hash)
        deep_merge!(target[key], value)
      else
        target[key] = value
      end
    end
  end

  # Build a single merged hash: machine base → human overlay → English fallback.
  # @param human [Hash] nested human translations {locale: {key: value}}
  # @param machine [Hash] nested machine translations
  # @return [Hash] flat hash {locale: {"dotted.key" => value}} with frozen values
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
      )
    end
    result
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
    all_keys = english.keys | machine.keys | human.keys
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
  # @return [Hash, nil] merged pluralization hash with symbol keys
  def merge_pluralization(human, machine, english)
    result = {}
    PLURAL_KEYS.each do |pk|
      h = plural_value(human, pk)
      m = plural_value(machine, pk)
      e = plural_value(english, pk)

      # Precedence: human > machine > english
      value = pick_present(h, m, e)
      result[pk] = value if present_string?(value)
    end
    result.empty? ? nil : result
  end

  # Get a value from a pluralization hash, checking both symbol and string keys.
  # @param hash [Hash, nil] the pluralization hash
  # @param key [Symbol] the plural key (:one, :other, etc.)
  # @return [String, nil] the value or nil
  def plural_value(hash, key)
    return unless hash.is_a?(Hash)

    hash[key] || hash[key.to_s]
  end

  # Return first present string value from arguments.
  # @param values [Array<String, nil>] values in precedence order
  # @return [String, nil] first present value or nil
  def pick_present(*values)
    values.find { |v| present_string?(v) }
  end

  # Check if a hash is a pluralization hash (contains :one, :other, etc.).
  # Checks both symbol and string keys since YAML may load either.
  # @param value [Object] the value to check
  # @return [Boolean] true if hash contains pluralization keys
  def pluralization_hash?(value)
    return false unless value.is_a?(Hash)

    PLURAL_KEYS.any? { |k| value.key?(k) || value.key?(k.to_s) }
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
    key_str = key.to_s
    # Leading dot means "ignore scope, use absolute path from root"
    return key_str.delete_prefix('.') if key_str.start_with?('.')
    return key_str if scope.nil?

    scope_str = scope.is_a?(Array) ? scope.join('.') : scope.to_s
    "#{scope_str}.#{key_str}"
  end

  # Extract a subtree of translations for a partial key.
  # @param locale [Symbol] the locale
  # @param prefix [String] the partial key prefix (empty string for root)
  # @return [Hash, nil] nested hash of translations under prefix, or nil if none
  def extract_subtree(locale, prefix)
    locale_translations = @translations[locale]
    return nil unless locale_translations

    # Empty prefix means return all translations as nested hash
    if prefix.empty?
      result = ActiveSupport::HashWithIndifferentAccess.new
      locale_translations.each do |full_key, value|
        set_nested_value(result, full_key, value)
      end
      return result.empty? ? nil : deep_freeze(result)
    end

    prefix_with_dot = "#{prefix}."
    matching_keys = locale_translations.keys.select { |k| k.start_with?(prefix_with_dot) }
    return nil if matching_keys.empty?

    # Build nested hash from flat keys with indifferent access
    result = ActiveSupport::HashWithIndifferentAccess.new
    matching_keys.each do |full_key|
      relative_key = full_key.delete_prefix(prefix_with_dot)
      set_nested_value(result, relative_key, locale_translations[full_key])
    end
    deep_freeze(result)
  end

  # Set a value in a nested hash using a dotted key path.
  # @param hash [Hash] the hash to modify
  # @param key_path [String] dotted key path (e.g., "misc.in_javascript.key1")
  # @param value [Object] the value to set
  def set_nested_value(hash, key_path, value)
    keys = key_path.split('.')
    last_key = keys.pop
    target = keys.reduce(hash) { |h, k| h[k] ||= ActiveSupport::HashWithIndifferentAccess.new }
    target[last_key] = value
  end

  # Deep freeze a hash and all nested hashes.
  # @param hash [Hash] the hash to freeze
  # @return [Hash] the frozen hash
  def deep_freeze(hash)
    hash.each_value { |v| deep_freeze(v) if v.is_a?(Hash) }
    hash.freeze
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

  # Return default pluralization rule for a locale.
  # English and most Western languages use :one for 1, :other for everything else.
  # @param locale [Symbol] the locale
  # @return [Proc] pluralization rule lambda
  def default_plural_rule(_locale)
    # Default English-style rule: one for 1, other for everything else
    ->(n) { n == 1 ? :one : :other }
  end
end
# rubocop:enable Style/Send, Metrics/ClassLength
