# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'no_dup_coder'

# Test NoDupCoder, which replaces DupCoder in MemoryStore to avoid
# duplicating frozen strings on every cache read.
class NoDupCoderTest < ActiveSupport::TestCase
  test 'dump freezes string values' do
    entry = ActiveSupport::Cache::Entry.new('hello world')
    dumped = NoDupCoder.dump(entry)
    assert dumped.value.frozen?, 'dumped string value should be frozen'
  end

  test 'dump uses Marshal for non-string values' do
    entry = ActiveSupport::Cache::Entry.new([1, 2, 3])
    dumped = NoDupCoder.dump(entry)
    assert dumped.value.is_a?(String)
    assert dumped.value.start_with?("\x04\x08".b)
  end

  test 'dump passes through nil, true, and numeric values unchanged' do
    entry_nil = ActiveSupport::Cache::Entry.new(nil)
    assert_nil NoDupCoder.dump(entry_nil).value

    [true, 42, 3.14].each do |val|
      entry = ActiveSupport::Cache::Entry.new(val)
      dumped = NoDupCoder.dump(entry)
      assert_equal val, dumped.value
    end
  end

  test 'load returns frozen strings directly without duplication' do
    original = 'cached content'.dup.freeze
    entry = ActiveSupport::Cache::Entry.new(original)
    loaded = NoDupCoder.load(entry)
    assert_equal 'cached content', loaded.value
    assert loaded.value.frozen?
    # The key optimization: same object, no dup
    assert_same original, loaded.value
  end

  test 'load deserializes Marshal-encoded values' do
    array = [1, 2, 3]
    marshaled = Marshal.dump(array)
    entry = ActiveSupport::Cache::Entry.new(marshaled)
    loaded = NoDupCoder.load(entry)
    assert_equal array, loaded.value
  end

  test 'dump preserves expires_at and version metadata' do
    expires = 1.hour.from_now.to_f
    entry = ActiveSupport::Cache::Entry.new('value',
                                            expires_at: expires,
                                            version: 'v1')
    dumped = NoDupCoder.dump(entry)
    assert_equal expires, dumped.expires_at
    assert_equal 'v1', dumped.version
  end

  test 'dump_compressed works with compressible entries' do
    large_value = 'x' * 2048
    entry = ActiveSupport::Cache::Entry.new(large_value)
    result = NoDupCoder.dump_compressed(entry, 1024)
    # Either compressed or dumped, both are valid
    assert result.is_a?(ActiveSupport::Cache::Entry)
  end

  test 'dump_compressed falls back to dump for small entries' do
    entry = ActiveSupport::Cache::Entry.new('small')
    result = NoDupCoder.dump_compressed(entry, 1024)
    assert result.is_a?(ActiveSupport::Cache::Entry)
    assert result.value.frozen?
  end

  test 'SafeBuffer values preserve html_safe through dump/load cycle' do
    safe = '<p>hello</p>'.html_safe
    entry = ActiveSupport::Cache::Entry.new(safe)
    dumped = NoDupCoder.dump(entry)
    loaded = NoDupCoder.load(dumped)
    assert loaded.value.html_safe?, 'html_safe? should be preserved'
    assert_equal '<p>hello</p>', loaded.value
  end

  test 'already frozen strings are not re-duped on dump' do
    frozen_str = 'already frozen'
    entry = ActiveSupport::Cache::Entry.new(frozen_str)
    dumped = NoDupCoder.dump(entry)
    assert_same frozen_str, dumped.value
  end

  test 'Rails.cache uses NoDupCoder and returns frozen values' do
    Rails.cache.write('nodup_test_key', 'test_value')
    result = Rails.cache.read('nodup_test_key')
    assert_equal 'test_value', result
    assert result.frozen?, 'cached string should be frozen'
  ensure
    Rails.cache.delete('nodup_test_key')
  end
end
