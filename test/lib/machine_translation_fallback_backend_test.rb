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
  end

  test 'reload! is a no-op and translations still work' do
    @backend.reload!
    assert I18n.t('feed_title', locale: :en).present?
  end

  test 'eager_load! can be called without error' do
    assert_nothing_raised { @backend.eager_load! }
  end

  test 'translations method returns human translations hash' do
    translations = @backend.send(:translations)
    assert translations.is_a?(Hash) && translations.key?(:en)
  end

  # rubocop:disable Rails/DotSeparatedKeys
  test 'translate handles scope parameter with human translations' do
    assert_equal 'Notions de base', I18n.t('Basics', scope: :headings, locale: :fr)
  end

  test 'translate handles scope parameter with machine translations' do
    assert_equal 'Contrôles', I18n.t('Controls', scope: :headings, locale: :fr)
  end

  test 'translate handles dotted key equivalent to scope parameter' do
    with_scope = I18n.t('Basics', scope: :headings, locale: :fr)
    assert_equal with_scope, I18n.t('headings.Basics', locale: :fr)
  end

  test 'translate handles nested scope array' do
    assert_equal 'Submit (and exit)', I18n.t('submit_and_exit', scope: %i[projects edit], locale: :en)
  end
  # rubocop:enable Rails/DotSeparatedKeys

  test 'process_translation handles regular values' do
    assert_equal 'value', @backend.send(:process_translation, :en, 'test', 'value', {})
  end

  test 'process_translation handles pluralization with count' do
    assert_equal '1 Project', I18n.t('projects_count', count: 1, locale: :en)
    assert_equal '5 Projects', I18n.t('projects_count', count: 5, locale: :en)
  end

  test 'build_lookup_key returns key as string when no scope' do
    assert_equal 'key', @backend.send(:build_lookup_key, 'key', nil)
    assert_equal 'key', @backend.send(:build_lookup_key, :key, nil)
  end

  test 'build_lookup_key handles symbol and array scope' do
    assert_equal 'headings.Controls', @backend.send(:build_lookup_key, 'Controls', :headings)
    assert_equal 'projects.edit.title', @backend.send(:build_lookup_key, 'title', %i[projects edit])
  end

  test 'flat hash uses dotted string keys' do
    human_flat = @backend.instance_variable_get(:@human_flat)
    assert human_flat[:en].key?('feed_title')
    assert human_flat[:en].key?('layouts.projects')
  end

  test 'flat hash preserves pluralization hashes' do
    human_flat = @backend.instance_variable_get(:@human_flat)
    projects_count = human_flat[:en]['projects_count']
    assert projects_count.is_a?(Hash) && projects_count.key?(:one) && projects_count.key?(:other)
  end

  test 'flat hash freezes values and locale hashes' do
    human_flat = @backend.instance_variable_get(:@human_flat)
    assert human_flat[:en]['feed_title'].frozen?, 'String values should be frozen'
    assert human_flat[:en].frozen?, 'Locale hash should be frozen'
  end

  test 'present_value? handles nil, empty, and valid values' do
    assert_not @backend.send(:present_value?, nil)
    assert_not @backend.send(:present_value?, '')
    assert @backend.send(:present_value?, 'hello')
    assert @backend.send(:present_value?, false) # false is valid
  end

  test 'present_value? handles pluralization hashes' do
    assert @backend.send(:present_value?, { one: 'item', other: 'items' })
    assert_not @backend.send(:present_value?, { one: '', other: '' })
  end
end
