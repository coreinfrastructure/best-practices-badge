# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class MachineTranslationFallbackBackendTest < ActiveSupport::TestCase
  def setup
    @backend = I18n.backend
  end

  test 'available_locales includes both human and machine locales' do
    locales = @backend.available_locales
    assert_includes locales, :en
    assert_includes locales, :fr
    # Machine translations should be included
    assert locales.is_a?(Array)
  end

  test 'reload! updates cached translation references' do
    # Force reload
    @backend.reload!
    # Verify we can still translate after reload
    translation = I18n.t('feed_title', locale: :en)
    assert translation.present?
  end

  test 'eager_load! can be called without error' do
    # This method is optional but should not crash if called
    assert_nothing_raised do
      @backend.eager_load!
    end
  end

  test 'lookup handles string keys in translation hash' do
    # Create a test translation hash with string keys to test line 102
    test_translations = { en: { 'string_key' => 'value' } }
    result = @backend.send(:lookup_in_translations, test_translations, :en, 'string_key')
    assert_equal 'value', result
  end

  test 'translations method returns human translations hash' do
    # Used by tests and introspection code
    translations = @backend.send(:translations)
    assert translations.is_a?(Hash)
    assert translations.key?(:en)
  end

  # rubocop:disable Rails/DotSeparatedKeys
  test 'translate handles scope parameter with human translations' do
    # Test with a known human translation (Basics is in translation.fr.yml)
    # We specifically test scope: parameter here (not dotted keys)
    translation = I18n.t('Basics', scope: :headings, locale: :fr)
    assert_equal 'Notions de base', translation
  end

  test 'translate handles scope parameter with machine translations' do
    # Test with a machine-only translation (Controls is only in machine_translations/fr.yml)
    # We specifically test scope: parameter here (not dotted keys)
    translation = I18n.t('Controls', scope: :headings, locale: :fr)
    assert_equal 'Contrôles', translation
  end

  test 'translate handles dotted key equivalent to scope parameter' do
    # Both forms should return the same result
    with_scope = I18n.t('Basics', scope: :headings, locale: :fr)
    with_dot = I18n.t('headings.Basics', locale: :fr)
    assert_equal with_scope, with_dot
  end

  test 'translate handles nested scope array' do
    # Scope can be an array of nested keys
    # We specifically test scope: parameter here (not dotted keys)
    translation = I18n.t('submit_and_exit', scope: %i[projects edit], locale: :en)
    assert_equal 'Submit (and exit)', translation
  end
  # rubocop:enable Rails/DotSeparatedKeys

  test 'normalize method handles nil scope' do
    result = @backend.send(:normalize, 'key', nil)
    assert_equal 'key', result
  end

  test 'normalize method handles empty scope' do
    result = @backend.send(:normalize, 'key', [])
    assert_equal 'key', result
  end

  test 'normalize method handles single scope' do
    result = @backend.send(:normalize, 'Controls', :headings)
    assert_equal 'headings.Controls', result
  end

  test 'normalize method handles nested scope array' do
    result = @backend.send(:normalize, 'title', %i[projects edit])
    assert_equal 'projects.edit.title', result
  end

  test 'process_translation handles regular values' do
    # Process a simple string value
    result = @backend.send(:process_translation, :en, 'test', 'value', {})
    assert_equal 'value', result
  end

  test 'process_translation handles pluralization with count' do
    # Test pluralization when count option is present
    # Use a real translation that supports pluralization
    I18n.backend.store_translations(:en, { items: { one: '1 item', other: '%<count>s items' } })
    result = I18n.t('items', count: 5, locale: :en)
    assert_equal '5 items', result
  end

  test 'available_locales returns union of human and machine locales' do
    locales = @backend.available_locales
    assert_kind_of Array, locales
    # Should include both human and machine locale keys
    assert_includes locales, :en
    assert_includes locales, :fr
  end

  test 'lookup_in_translations returns nil for Hash values' do
    # Create translations with a Hash value (intermediate node, not leaf)
    test_translations = { en: { intermediate: { leaf: 'value' } } }
    # Looking up just 'intermediate' should return nil (not the Hash)
    result = @backend.send(:lookup_in_translations, test_translations, :en, 'intermediate')
    assert_nil result
  end

  test 'lookup_in_translations handles false values correctly' do
    # False is a valid translation value, should not be treated as nil
    test_translations = { en: { flag: false } }
    result = @backend.send(:lookup_in_translations, test_translations, :en, 'flag')
    assert_equal false, result
  end

  test 'lookup_in_translations returns nil for missing keys' do
    test_translations = { en: { existing: 'value' } }
    result = @backend.send(:lookup_in_translations, test_translations, :en, 'nonexistent')
    assert_nil result
  end
end
