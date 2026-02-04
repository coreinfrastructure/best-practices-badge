# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class MachineTranslationFallbackBackendTest < ActiveSupport::TestCase
  def setup
    @backend = I18n.backend
  end

  # === Public Interface Tests ===

  test 'available_locales includes all locales' do
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

  # === Translation Lookup Tests ===

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

  test 'translate uses English fallback for missing translations' do
    # feed_title exists in English, should fall back for locales without it
    result = I18n.t('feed_title', locale: :en)
    assert result.present?
    assert_includes result, 'OpenSSF'
  end

  test 'pluralization works with count' do
    assert_equal '1 Project', I18n.t('projects_count', count: 1, locale: :en)
    assert_equal '5 Projects', I18n.t('projects_count', count: 5, locale: :en)
  end

  # === Merged Hash Structure Tests ===

  test 'merged hash uses dotted string keys' do
    translations = @backend.instance_variable_get(:@translations)
    assert translations[:en].key?('feed_title')
    assert translations[:en].key?('layouts.projects')
  end

  test 'merged hash preserves pluralization hashes' do
    translations = @backend.instance_variable_get(:@translations)
    projects_count = translations[:en]['projects_count']
    assert projects_count.is_a?(Hash)
    assert projects_count.key?(:one) && projects_count.key?(:other)
  end

  test 'merged hash freezes values' do
    translations = @backend.instance_variable_get(:@translations)
    assert translations[:en]['feed_title'].frozen?
    assert translations[:en].frozen?
  end

  # === build_lookup_key Tests ===

  test 'build_lookup_key returns key as string when no scope' do
    assert_equal 'key', @backend.send(:build_lookup_key, 'key', nil)
    assert_equal 'key', @backend.send(:build_lookup_key, :key, nil)
  end

  test 'build_lookup_key handles symbol and array scope' do
    assert_equal 'headings.Controls', @backend.send(:build_lookup_key, 'Controls', :headings)
    assert_equal 'projects.edit.title', @backend.send(:build_lookup_key, 'title', %i[projects edit])
  end

  # === Merge Logic Tests ===

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

    assert_equal 'human one', result[:one]       # human wins
    assert_equal 'machine other', result[:other] # machine fills in
    assert_equal 'english zero', result[:zero]   # english fills in
  end

  test 'present_string? handles various inputs' do
    assert @backend.send(:present_string?, 'hello')
    assert @backend.send(:present_string?, false) # false is valid
    assert_not @backend.send(:present_string?, nil)
    assert_not @backend.send(:present_string?, '')
  end

  test 'present_value? handles pluralization hashes' do
    assert @backend.send(:present_value?, { one: 'item', other: 'items' })
    assert_not @backend.send(:present_value?, { one: '', other: '' })
    assert_not @backend.send(:present_value?, nil)
  end

  test 'pluralization_hash? detects plural keys' do
    assert @backend.send(:pluralization_hash?, { one: 'x', other: 'y' })
    assert @backend.send(:pluralization_hash?, { zero: 'none' })
    assert_not @backend.send(:pluralization_hash?, { foo: 'bar' })
    assert_not @backend.send(:pluralization_hash?, 'string')
  end
end
