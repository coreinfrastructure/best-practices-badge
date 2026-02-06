# frozen_string_literal: true

# Copyright the OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Rails/RenderInline
class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test 'cache_frozen stores a frozen SafeBuffer in the cache' do
    key = "cache_frozen_test_#{SecureRandom.hex(4)}"
    result = render_cache_frozen(key, 'Hello from cache_frozen')
    assert_includes result, 'Hello from cache_frozen'
    cached = read_raw_cached(key)
    assert_equal 'Hello from cache_frozen', cached
    assert cached.frozen?, 'value in cache store should be frozen'
    assert_instance_of ActiveSupport::SafeBuffer, cached
  ensure
    delete_raw_cached(key)
  end

  test 'cache_frozen returns frozen SafeBuffer directly on cache hit' do
    key = "cache_frozen_hit_#{SecureRandom.hex(4)}"
    render_cache_frozen(key, 'first render')
    cached_object = read_raw_cached(key)
    # Second render should reuse the same frozen object from cache
    result = render_cache_frozen(key, 'second render')
    assert_includes result, 'first render'
    assert_not_includes result, 'second render'
    assert_same cached_object, read_raw_cached(key)
  ensure
    delete_raw_cached(key)
  end

  test 'cache_frozen yields directly when caching disabled' do
    helper = Object.new
    helper.extend(ApplicationHelper)
    no_cache_controller = Struct.new(:perform_caching).new(false)
    helper.define_singleton_method(:controller) { no_cache_controller }
    yielded = false
    helper.cache_frozen('key') { yielded = true }
    assert yielded, 'cache_frozen should yield when caching is disabled'
  end

  test 'cache_frozen_if caches when condition is true' do
    key = "cache_frozen_if_true_#{SecureRandom.hex(4)}"
    result = render_cache_frozen_if(true, key, 'cached content')
    assert_includes result, 'cached content'
    cached = read_raw_cached(key)
    assert_equal 'cached content', cached
    assert cached.frozen?, 'value in cache store should be frozen'
  ensure
    delete_raw_cached(key)
  end

  test 'cache_frozen_if yields without caching when condition is false' do
    key = "cache_frozen_if_false_#{SecureRandom.hex(4)}"
    result = render_cache_frozen_if(false, key, 'uncached content')
    assert_includes result, 'uncached content'
    assert_nil read_raw_cached(key)
  ensure
    delete_raw_cached(key)
  end

  test 'cache_frozen_unless caches when condition is false' do
    key = "cache_frozen_unless_#{SecureRandom.hex(4)}"
    result = render_cache_frozen_unless(false, key, 'cached content')
    assert_includes result, 'cached content'
    cached = read_raw_cached(key)
    assert_equal 'cached content', cached
    assert cached.frozen?, 'value in cache store should be frozen'
  ensure
    delete_raw_cached(key)
  end

  private

  # Render cache_frozen in a minimal ERB template so the output buffer
  # captures content correctly (block must concat to buffer, not just
  # return a string).
  def render_cache_frozen(key, content)
    render(inline: "<% cache_frozen('#{key}', skip_digest: true)" \
                   " do %>#{content}<% end %>")
  end

  def render_cache_frozen_if(condition, key, content)
    render(inline: "<% cache_frozen_if(#{condition}, '#{key}'," \
                   " skip_digest: true) do %>#{content}<% end %>")
  end

  def render_cache_frozen_unless(condition, key, content)
    render(inline: "<% cache_frozen_unless(#{condition}, '#{key}'," \
                   " skip_digest: true) do %>#{content}<% end %>")
  end

  # Read directly from the cache store using the same key format
  # that cache_frozen uses, bypassing read_fragment's SafeBuffer
  # re-wrapping.
  def cache_key_for(key)
    controller.combined_fragment_cache_key(key)
  end

  def read_raw_cached(key)
    Rails.cache.read(cache_key_for(key))
  end

  def delete_raw_cached(key)
    Rails.cache.delete(cache_key_for(key))
  end
end
# rubocop:enable Rails/RenderInline
