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
class MachineTranslationFallbackBackend < I18n::Backend::Simple
  def initialize(human_backend, machine_backend)
    super()
    @human_backend = human_backend
    @machine_backend = machine_backend
    # Cache backend translation hashes to avoid repeated method calls
    @human_translations = @human_backend.send(:translations)
    @machine_translations = @machine_backend.send(:translations)
  end

  def translate(locale, key, options = {})
    # Try human translations first (check raw hash to avoid fallback behavior)
    human_value = lookup_in_translations(@human_translations, locale, key)
    return human_value if human_value.present?

    # Human translation missing/empty - try machine translations
    machine_value = lookup_in_translations(@machine_translations, locale, key)
    return machine_value if machine_value.present?

    # Neither has it - use default fallback behavior (English)
    @human_backend.translate(locale, key, options)
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

  private

  # Look up a key directly in a translations hash.
  # Returns the value if found and non-nil, otherwise nil.
  # Optimized to minimize object allocation - critical for memory-constrained production.
  def lookup_in_translations(translations, locale, key)
    return nil unless translations

    current = translations[locale]
    return nil unless current

    # Handle Symbol keys directly (fast path - no object creation)
    if key.is_a?(Symbol)
      # For symbol keys, check if it contains namespace separator
      # Symbol#to_s is relatively cheap but we avoid it when possible
      key_str = key.to_s
      return current[key] || current[key_str] unless key_str.include?('.')
      
      # Navigate nested hash for namespaced keys
      # We must convert to string and split - unavoidable but minimized
      key_str.split('.').each do |part|
        current = current[part.to_sym] || current[part]
        return nil unless current
      end
      return current
    end

    # Handle String keys
    # Fast path: no dots means single-level lookup (common case)
    unless key.include?('.')
      return current[key.to_sym] || current[key]
    end

    # Navigate nested hash for namespaced keys
    # split('.') creates array - unavoidable but we iterate without additional objects
    key.split('.').each do |part|
      # Try symbol first (more common), then string
      # Note: to_sym on existing string reuses interned symbol - minimal cost
      current = current[part.to_sym] || current[part]
      return nil unless current
    end

    current
  end
end
