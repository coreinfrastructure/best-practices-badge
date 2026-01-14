# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class InvokeRedcarpetTest < ActiveSupport::TestCase
  # Reset between tests to ensure clean state
  def setup
    InvokeRedcarpet.instance_variable_set(:@previous_content, nil)
  end

  test 'invoke_and_sanitize renders simple markdown' do
    result = InvokeRedcarpet.invoke_and_sanitize('*emphasis*')
    assert_equal "<p><em>emphasis</em></p>\n", result
    assert result.html_safe?
  end

  test 'invoke_and_sanitize handles blank content' do
    result = InvokeRedcarpet.invoke_and_sanitize('')
    # Redcarpet returns empty string for empty input
    assert_equal '', result
    assert result.html_safe?
  end

  test 'invoke_and_sanitize stores previous content on success' do
    InvokeRedcarpet.invoke_and_sanitize('first content')
    previous = InvokeRedcarpet.instance_variable_get(:@previous_content)
    assert_equal 'first content', previous

    InvokeRedcarpet.invoke_and_sanitize('second content')
    previous = InvokeRedcarpet.instance_variable_get(:@previous_content)
    assert_equal 'second content', previous
  end

  test 'invoke_and_sanitize with force_bad_type raises TypeError' do
    error =
      assert_raises(TypeError) do
        InvokeRedcarpet.invoke_and_sanitize('test', raise_on_error: true, force_bad_type: true)
      end

    assert_match(/wrong type/i, error.message)
  end

  test 'invoke_and_sanitize with force_bad_type returns escaped content when not raising' do
    result = InvokeRedcarpet.invoke_and_sanitize('<test>',
                                                 raise_on_error: false,
                                                 force_bad_type: true)
    # Should return HTML-escaped content as fallback
    assert_equal '&lt;test&gt;', result
    assert result.html_safe?
  end

  test 'invoke_and_sanitize with force_exception raises when raise_on_error true' do
    test_error = StandardError.new('Test error')

    error =
      assert_raises(StandardError) do
        InvokeRedcarpet.invoke_and_sanitize('test',
                                            raise_on_error: true,
                                            force_exception: test_error)
      end

    assert_equal 'Test error', error.message
  end

  test 'invoke_and_sanitize with force_exception returns escaped when raise_on_error false' do
    test_error = StandardError.new('Test error')

    result = InvokeRedcarpet.invoke_and_sanitize('<b>test</b>',
                                                 raise_on_error: false,
                                                 force_exception: test_error)

    # Should return HTML-escaped content as fallback
    assert_equal '&lt;b&gt;test&lt;/b&gt;', result
    assert result.html_safe?
  end

  test 'invoke_and_sanitize resets processor on exception' do
    # Force an exception
    test_error = StandardError.new('Test error')
    result = InvokeRedcarpet.invoke_and_sanitize('*test*',
                                                 raise_on_error: false,
                                                 force_exception: test_error)
    assert_equal '*test*', result # Lightly escaped
  end

  test 'invoke_and_sanitize handles error when previous content exists' do
    # First, do a successful render to set @previous_content
    InvokeRedcarpet.invoke_and_sanitize('previous successful content')

    # Verify previous content was stored
    assert_equal 'previous successful content',
                 InvokeRedcarpet.instance_variable_get(:@previous_content)

    # Now force an exception - this exercises the log_render_error path
    # with previous_content set.
    test_error = RuntimeError.new('Simulated error')
    result = InvokeRedcarpet.invoke_and_sanitize('current *failing* <script> content',
                                                 raise_on_error: false,
                                                 force_exception: test_error)

    # Verify it returned escaped content as fallback
    assert_equal 'current *failing* &lt;script&gt; content', result
    assert result.html_safe?
  end
end
# rubocop:enable Metrics/ClassLength
