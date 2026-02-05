# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class MachineTranslationFallbackBackendTest < ActiveSupport::TestCase
  def setup
    @backend = I18n.backend
  end

  test 'available_locales includes all locales' do
    locales = @backend.available_locales
    assert_includes locales, :en
    assert_includes locales, :fr
  end

  test 'reload! and eager_load! are no-ops' do
    @backend.reload!
    @backend.eager_load!
    assert I18n.t('feed_title', locale: :en).present?
  end

  test 'translations returns flat hash with dotted keys' do
    t = @backend.translations
    assert t.is_a?(Hash) && t.key?(:en)
    assert t[:en].key?('feed_title') && t[:en].key?('layouts.projects')
  end

  # rubocop:disable Rails/DotSeparatedKeys
  test 'translate handles scope parameter' do
    assert_equal 'Notions de base', I18n.t('Basics', scope: :headings, locale: :fr)
    assert_equal 'Contrôles', I18n.t('Controls', scope: :headings, locale: :fr)
    assert_equal I18n.t('Basics', scope: :headings, locale: :fr), I18n.t('headings.Basics', locale: :fr)
    assert_equal 'Submit (and exit)', I18n.t('submit_and_exit', scope: %i[projects edit], locale: :en)
  end
  # rubocop:enable Rails/DotSeparatedKeys

  test 'translate uses English fallback and returns nil for missing' do
    result = I18n.t('feed_title', locale: :fr)
    assert result.present? && result.include?('OpenSSF')
    assert_nil @backend.translate(:en, 'nonexistent.key')
  end

  test 'pluralization works with count' do
    assert_equal '1 Project', I18n.t('projects_count', count: 1, locale: :en)
    assert_equal '5 Projects', I18n.t('projects_count', count: 5, locale: :en)
  end

  test 'merged hash preserves pluralization hashes and freezes string values' do
    t = @backend.translations
    pc = t[:en]['projects_count']
    assert pc.is_a?(Hash) && pc.key?(:one) && pc.key?(:other)
    # String values are frozen, but hashes remain mutable for I18n compatibility
    assert t[:en]['feed_title'].frozen?
  end

  test 'build_lookup_key handles various inputs' do
    assert_equal 'key', @backend.send(:build_lookup_key, 'key', nil)
    assert_equal 'key', @backend.send(:build_lookup_key, :key, nil)
    assert_equal 'headings.Controls', @backend.send(:build_lookup_key, 'Controls', :headings)
    assert_equal 'projects.edit.title', @backend.send(:build_lookup_key, 'title', %i[projects edit])
  end

  test 'merge_value prefers human over machine over english' do
    assert_equal 'human', @backend.send(:merge_value, 'human', 'machine', 'english')
    assert_equal 'machine', @backend.send(:merge_value, nil, 'machine', 'english')
    assert_equal 'machine', @backend.send(:merge_value, '', 'machine', 'english')
    assert_equal 'english', @backend.send(:merge_value, nil, nil, 'english')
  end

  test 'merge_pluralization merges at key level' do
    human = { one: 'human one' }
    machine = { one: 'machine one', other: 'machine other' }
    english = { zero: 'english zero', one: 'english one', other: 'english other' }
    result = @backend.send(:merge_pluralization, human, machine, english)
    assert_equal 'human one', result[:one]
    assert_equal 'machine other', result[:other]
    assert_equal 'english zero', result[:zero]
  end

  test 'present_string? and present_value? handle various inputs' do
    assert @backend.send(:present_string?, 'hello')
    assert @backend.send(:present_string?, false)
    assert_not @backend.send(:present_string?, nil)
    assert_not @backend.send(:present_string?, '')
    assert @backend.send(:present_value?, { one: 'item', other: 'items' })
    assert_not @backend.send(:present_value?, { one: '', other: '' })
  end

  test 'pluralization_hash? detects plural keys' do
    assert @backend.send(:pluralization_hash?, { one: 'x', other: 'y' })
    assert @backend.send(:pluralization_hash?, { zero: 'none' })
    assert_not @backend.send(:pluralization_hash?, { foo: 'bar' })
    assert_not @backend.send(:pluralization_hash?, 'string')
  end

  test 'load_yaml_files loads files and handles missing gracefully' do
    files = Rails.root.glob('config/locales/en.yml')
    result = @backend.send(:load_yaml_files, files)
    assert result.is_a?(Hash) && result.key?(:en)
    assert_equal({}, @backend.send(:load_yaml_files, ['/nonexistent/file.yml']))
  end

  test 'lookup method finds translations with scope' do
    # Test direct lookup without scope (or with empty array scope)
    result = @backend.lookup(:en, 'feed_title', [])
    assert_equal 'OpenSSF Best Practices BadgeApp Updated Projects', result

    # Test lookup with scope as symbol
    result = @backend.lookup(:en, 'projects', [:layouts])
    assert_equal 'Projects', result

    # Test lookup with nil scope
    result = @backend.lookup(:en, 'hello', nil)
    assert_equal 'Hello world', result
  end

  test 'exists? method checks for translation presence' do
    assert @backend.exists?(:en, 'feed_title')
    assert @backend.exists?(:en, 'projects', scope: :layouts)
    assert_not @backend.exists?(:en, 'nonexistent_key')
    assert_not @backend.exists?(:en, 'nonexistent', scope: :nonexistent)
  end

  test 'store_translations warns and ignores attempts to add translations' do
    # Just ensure it doesn't raise an exception
    assert_nothing_raised do
      @backend.store_translations(:en, { test_key: 'test value' })
    end
    # Verify the key wasn't actually added
    assert_nil @backend.lookup(:en, 'test_key', [])
  end

  test 'translate returns default value when key not found' do
    result = @backend.translate(:en, 'missing.key', default: 'default value')
    assert_equal 'default value', result

    # Test with nil default (should return nil)
    result = @backend.translate(:en, 'missing.key', default: nil)
    assert_nil result
  end

  test 'nested_hash returns proper nested structure' do
    result = @backend.nested_hash(:en, 'locale_name')
    assert result.is_a?(Hash)
    assert_equal 'English', result[:en]
    assert_equal 'French', result[:fr]

    # Test with non-existent path
    result = @backend.nested_hash(:en, 'nonexistent.path')
    assert_nil result

    # Test with invalid locale
    result = @backend.nested_hash(:invalid_locale, 'locale_name')
    assert_nil result
  end

  test 'nested_hash handles deeply nested paths' do
    result = @backend.nested_hash(:en, 'projects.edit')
    assert result.is_a?(Hash)
    assert result.keys.any? # Should have some keys
  end

  test 'pluralization parent keys are created for single plural forms' do
    # Access the pluralization hash that should have been created
    t = @backend.translations
    # The test_pluralization_only_one should create a parent hash
    result = t[:en]['test_pluralization_only_one']
    assert result.is_a?(Hash)
    assert_equal 'just one item', result[:one]
  end

  test 'merge_locale creates pluralization parent hashes' do
    # Test that parent keys are created for plural entries
    human = { 'items.one' => 'one item', 'items.other' => 'other items' }
    machine = {}
    english = {}
    result = @backend.send(:merge_locale, human, machine, english)

    # Should create 'items' parent hash
    assert result.key?('items')
    assert result['items'].is_a?(Hash)
    assert_equal 'one item', result['items']['one']
    assert_equal 'other items', result['items']['other']
  end

  test 'merge_locale skips empty parent keys for top-level plurals' do
    # Plurals without a parent (shouldn't happen but should handle gracefully)
    human = { 'one' => 'single', 'other' => 'multiple' }
    machine = {}
    english = {}
    result = @backend.send(:merge_locale, human, machine, english)

    # Should have the flat keys but not try to create invalid parent
    assert_equal 'single', result['one']
    assert_equal 'multiple', result['other']
  end
end
# rubocop:enable Metrics/ClassLength
