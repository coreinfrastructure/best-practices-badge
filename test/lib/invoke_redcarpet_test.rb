# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class InvokeRedcarpetTest < ActiveSupport::TestCase
  # Reset the processor between tests to ensure clean state
  def setup
    InvokeRedcarpet.instance_variable_set(:@redcarpet_processor, nil)
    InvokeRedcarpet.instance_variable_set(:@previous_content, nil)
  end

  test 'ensure_processor_initialized creates processor when nil' do
    assert_nil InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
    InvokeRedcarpet.ensure_processor_initialized
    assert_instance_of Redcarpet::Markdown,
                       InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
  end

  test 'ensure_processor_initialized does not recreate when already set' do
    processor1 = InvokeRedcarpet.create_processor
    assert_instance_of Redcarpet::Markdown, processor1
    InvokeRedcarpet.instance_variable_set(:@redcarpet_processor, processor1)
    InvokeRedcarpet.ensure_processor_initialized
    processor2 = InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
    assert_same processor1, processor2
  end

  test 'check_processor_type succeeds with valid processor' do
    InvokeRedcarpet.ensure_processor_initialized
    # Should not raise
    assert_nothing_raised do
      InvokeRedcarpet.check_processor_type
    end
  end

  test 'check_processor_type raises TypeError for wrong type' do
    # Set processor to wrong type (Array)
    InvokeRedcarpet.instance_variable_set(:@redcarpet_processor, [])

    error =
      assert_raises(TypeError) do
        InvokeRedcarpet.check_processor_type
      end

    assert_match(/wrong type.*Array/i, error.message)
    # Should reset processor to nil
    assert_nil InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
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
    # Set a valid processor first
    InvokeRedcarpet.ensure_processor_initialized
    assert_not_nil InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)

    # Force an exception
    test_error = StandardError.new('Test error')
    InvokeRedcarpet.invoke_and_sanitize('test',
                                        raise_on_error: false,
                                        force_exception: test_error)

    # Processor should be reset to nil
    assert_nil InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
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
    result = InvokeRedcarpet.invoke_and_sanitize('current failing content',
                                                 raise_on_error: false,
                                                 force_exception: test_error)

    # Verify it returned escaped content as fallback
    assert_equal 'current failing content', result
    assert result.html_safe?
  end
end
# rubocop:enable Metrics/ClassLength
