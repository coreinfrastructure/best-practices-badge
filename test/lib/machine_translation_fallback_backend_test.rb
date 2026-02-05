# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

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
end
