# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Custom I18n backend that provides smart fallback from human to machine translations.
#
# CRITICAL SECURITY REQUIREMENT:
# Machine translations MUST NOT be in I18n.load_path because translation.io
# reads from I18n.load_path and would sync them to the remote service.
#
# This backend:
# 1. Checks human translations first (nil/empty = not translated)
# 2. Falls through to machine translations if human is missing/empty
# 3. Falls back to English if neither has a translation
#
# Human translations always win when present and non-empty.
#
# PERFORMANCE NOTE:
# This class is called on every translation lookup in the application.
# All methods are optimized to minimize object allocation.
#
# rubocop:disable Style/Send, Style/OptionHash
class MachineTranslationFallbackBackend < I18n::Backend::Simple
  def initialize(human_backend, machine_backend)
    super()
    @human_backend = human_backend
    @machine_backend = machine_backend
    # Cache backend translation hashes to avoid repeated method calls
    # Must use send() to access private translations method
    @human_translations = @human_backend.send(:translations)
    @machine_translations = @machine_backend.send(:translations)
  end

  # options parameter follows Rails I18n::Backend::Base signature
  def translate(locale, key, options = {})
    # Try human translations first (check raw hash to avoid fallback behavior)
    human_value = lookup_in_translations(@human_translations, locale, key)
    return process_translation(locale, key, human_value, options) if human_value.present?

    # Human translation missing/empty - try machine translations
    machine_value = lookup_in_translations(@machine_translations, locale, key)
    return process_translation(locale, key, machine_value, options) if machine_value.present?

    # Neither has it - use default fallback behavior (English)
    @human_backend.translate(locale, key, options)
  end

  # Process a translation value: resolve, then interpolate/pluralize
  def process_translation(locale, key, value, options)
    entry = resolve(locale, key, value, options.except(:default))
    return entry if entry.is_a?(::I18n::MissingTranslation)

    options.key?(:count) ? pluralize(locale, entry, options[:count]) : interpolate(locale, entry, options)
  end

  # Delegate other backend methods to human backend
  def available_locales
    @human_backend.available_locales | @machine_backend.available_locales
  end

  def reload!
    @human_backend.reload!
    @machine_backend.reload!
    # Update cached references after reload
    @human_translations = @human_backend.send(:translations)
    @machine_translations = @machine_backend.send(:translations)
  end

  def eager_load!
    @human_backend.eager_load! if @human_backend.respond_to?(:eager_load!)
    @machine_backend.eager_load! if @machine_backend.respond_to?(:eager_load!)
  end

  # Delegate to human backend's translations method for compatibility
  # Used by tests and introspection code
  def translations
    @human_translations
  end


  private

  # Look up a key directly in a translations hash.
  # Returns the value if found and non-nil, otherwise nil.
  # Returns nil if the value is a Hash (not a leaf translation).
  # Optimized to minimize object allocation - critical for memory-constrained production.
  # rubocop:disable Metrics/MethodLength
  def lookup_in_translations(translations, locale, key)
    return unless translations
    return if key.nil?

    current = translations[locale]
    return if current.nil?

    # Convert key to string if it's a symbol (needed for split)
    key_str = key.is_a?(Symbol) ? key.to_s : key

    # Navigate nested hash for namespaced keys (e.g., "projects.edit.title")
    # Nearly all translation keys in this app are namespaced (97%+)
    key_str.split('.').each do |part|
      # Try symbol first (more common), then string
      # Use has_key? to distinguish between "key doesn't exist" and "key exists with false value"
      current =
        if current.key?(part.to_sym)
          current[part.to_sym]
        elsif current.key?(part)
          current[part]
        else
          return nil
        end
      # Only return nil if the value is actually nil, not if it's false or empty string
      return nil if current.nil?
    end

    # Return nil if current is a Hash (intermediate node, not a leaf translation)
    # Rails expects String, Symbol, or nil - returning a Hash causes "undefined method `to_str'" errors
    current.is_a?(Hash) ? nil : current
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Style/Send, Style/OptionHash
