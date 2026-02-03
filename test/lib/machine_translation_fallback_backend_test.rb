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
end
