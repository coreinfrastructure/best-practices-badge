# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Custom I18n backend with flat hash lookup for zero per-lookup allocations.
#
# CRITICAL REQUIREMENT:
# Machine translations MUST NOT be in I18n.load_path because translation.io
# reads from I18n.load_path and would sync them to the remote service.
# This is not a *security* requirement, but it is needed for correct data.
#
# This backend precalculates a hash lookup to ensure that it:
# 1. Checks human translations first (nil/empty in source = not translated)
# 2. Falls through to machine translations if human is missing/empty
# 3. Falls back to English if neither has a translation
#
# PERFORMANCE: Pre-computes flat hashes at initialization. All strings frozen.

# rubocop:disable Style/Send, Style/OptionHash
class MachineTranslationFallbackBackend < I18n::Backend::Simple
  # Pluralization keys used by I18n to select singular/plural forms.
  PLURAL_KEYS = %i[zero one two few many other].to_set.freeze

  # Initialize the backend with human and machine translation backends.
  # Builds flat lookup hashes for O(1) translation retrieval.
  # @param human_backend [I18n::Backend::Simple] backend with human translations
  # @param machine_backend [I18n::Backend::Simple] backend with machine translations
  def initialize(human_backend, machine_backend)
    super()
    @human_backend = human_backend
    @machine_backend = machine_backend
    build_flat_lookups
  end

  # Look up a translation, checking human translations first, then machine.
  # Falls back to English via human_backend if neither has the translation.
  # @param locale [Symbol] the locale to translate for (e.g., :fr, :de)
  # @param key [String, Symbol] the translation key (e.g., 'projects.edit.title')
  # @param options [Hash] options including :scope, :count, :default, etc.
  # @return [String, Hash, Object] the translated value or fallback
  def translate(locale, key, options = {})
    lookup_key = build_lookup_key(key, options[:scope])

    value = @human_flat.dig(locale, lookup_key)
    return process_translation(locale, lookup_key, value, options) if present_value?(value)

    value = @machine_flat.dig(locale, lookup_key)
    return process_translation(locale, lookup_key, value, options) if present_value?(value)

    @human_backend.translate(locale, key, options)
  end

  # Return all available locales from both human and machine backends.
  # @return [Array<Symbol>] union of locales from both backends
  def available_locales
    @human_backend.available_locales | @machine_backend.available_locales
  end

  # No-op: translations are loaded once at startup and remain constant.
  # Clearing/reloading would waste memory and CPU rebuilding identical data.
  def reload!; end

  # Eagerly load translations in both backends.
  # Delegates to underlying backends if they support eager loading.
  def eager_load!
    @human_backend.eager_load! if @human_backend.respond_to?(:eager_load!)
    @machine_backend.eager_load! if @machine_backend.respond_to?(:eager_load!)
  end

  # Return the nested translations hash from the human backend.
  # Used by tests and introspection code for compatibility.
  # @return [Hash] nested translations hash keyed by locale
  def translations
    @human_backend.send(:translations)
  end

  private

  # Build flat lookup hashes from both backends' nested translations.
  # Called once at initialization; results are frozen and immutable.
  def build_flat_lookups
    @human_flat = build_flat_hash(@human_backend.send(:translations))
    @machine_flat = build_flat_hash(@machine_backend.send(:translations))
  end

  # Convert a nested translations hash into a flat hash with dotted keys.
  # @param nested [Hash] nested hash like {en: {projects: {title: "..."}}}
  # @return [Hash] frozen flat hash like {en: {"projects.title" => "..."}}
  def build_flat_hash(nested)
    result = {}
    nested.each { |locale, tree| result[locale] = flatten_tree(tree, '').freeze }
    result.freeze
  end

  # Recursively flatten a nested hash into dotted-key format.
  # Preserves pluralization hashes (with :one, :other, etc.) as leaf values.
  # @param hash [Hash] the hash to flatten
  # @param prefix [String] the key prefix built up during recursion
  # @return [Hash] flat hash with dotted string keys and frozen values
  def flatten_tree(hash, prefix)
    hash.each_with_object({}) do |(key, value), result|
      full_key = prefix.empty? ? key.to_s.freeze : "#{prefix}.#{key}".freeze
      if value.is_a?(Hash) && !pluralization_hash?(value)
        result.merge!(flatten_tree(value, full_key))
      else
        result[full_key] = freeze_value(value)
      end
    end
  end

  # Check if a hash is a pluralization hash (contains :one, :other, etc.).
  # @param hash [Hash] the hash to check
  # @return [Boolean] true if hash contains any pluralization keys
  def pluralization_hash?(hash)
    hash.each_key.any? { |k| PLURAL_KEYS.include?(k.to_sym) }
  end

  # Recursively freeze a value and all nested values.
  # @param value [Object] the value to freeze (String, Hash, or other)
  # @return [Object] the frozen value
  def freeze_value(value)
    if value.is_a?(Hash)
      return value.transform_values { |v| freeze_value(v) }
                  .freeze
    end
    value.freeze
  end

  # Build the lookup key by combining scope and key.
  # Avoids allocation when no scope is provided.
  # @param key [String, Symbol] the translation key
  # @param scope [Symbol, String, Array, nil] optional scope prefix
  # @return [String] the full dotted lookup key
  def build_lookup_key(key, scope)
    return key.to_s if scope.nil?

    scope_str = scope.is_a?(Array) ? scope.join('.') : scope.to_s
    "#{scope_str}.#{key}"
  end

  # Check if a value is present (non-nil, non-empty).
  # For hashes, checks if any value is present (for pluralization hashes).
  # @param value [Object] the value to check
  # @return [Boolean] true if value is present and usable
  def present_value?(value)
    return false if value.nil?
    return value.each_value.any? { |v| !v.nil? && v != '' } if value.is_a?(Hash)

    value != ''
  end

  # Process a found translation: resolve, pluralize, and interpolate.
  # @param locale [Symbol] the locale for pluralization rules
  # @param key [String] the translation key (for error messages)
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
# rubocop:enable Style/Send, Style/OptionHash
