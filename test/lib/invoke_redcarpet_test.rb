# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class InvokeRedcarpetTest < ActiveSupport::TestCase
  # Reset the processor between tests to ensure clean state
  def setup
    InvokeRedcarpet.instance_variable_set(:@redcarpet_processor, nil)
    InvokeRedcarpet.instance_variable_set(:@previous_content, nil)
  end

  test 'create_processor returns Redcarpet::Markdown instance' do
    processor = InvokeRedcarpet.create_processor
    assert_instance_of Redcarpet::Markdown, processor
  end

  test 'ensure_processor_initialized creates processor when nil' do
    assert_nil InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
    InvokeRedcarpet.ensure_processor_initialized
    assert_instance_of Redcarpet::Markdown,
                       InvokeRedcarpet.instance_variable_get(:@redcarpet_processor)
  end

  test 'ensure_processor_initialized does not recreate when already set' do
    processor1 = InvokeRedcarpet.create_processor
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

  test 'invoke_and_sanitize logs error with current and previous content' do
    # First call to set previous content
    InvokeRedcarpet.invoke_and_sanitize('previous content')

    # Simple mock logger that captures messages
    captured_messages = []
    mock_logger = Class.new do
      def initialize(messages_array)
        @messages = messages_array
      end

      def error(msg)
        @messages << msg
      end
    end.new(captured_messages)

    # Temporarily replace Rails.logger
    original_logger = Rails.logger
    Rails.logger = mock_logger

    begin
      # Force an exception with new content
      test_error = RuntimeError.new('Simulated error')
      InvokeRedcarpet.invoke_and_sanitize('current content',
                                          raise_on_error: false,
                                          force_exception: test_error)
    ensure
      Rails.logger = original_logger
    end

    assert(captured_messages.any? { |m| m.include?('RuntimeError') })
    assert(captured_messages.any? { |m| m.include?('current content') })
    assert(captured_messages.any? { |m| m.include?('previous content') })
  end

  test 'log_render_error includes exception details' do
    exception = RuntimeError.new('Test exception message')
    exception.set_backtrace(['line 1', 'line 2', 'line 3'])

    captured_messages = []
    mock_logger = Class.new do
      def initialize(messages_array)
        @messages = messages_array
      end

      def error(msg)
        @messages << msg
      end
    end.new(captured_messages)

    original_logger = Rails.logger
    Rails.logger = mock_logger

    begin
      InvokeRedcarpet.log_render_error(exception, 'current', 'previous')
    ensure
      Rails.logger = original_logger
    end

    assert(captured_messages.any? { |m| m.include?('RuntimeError') })
    assert(captured_messages.any? { |m| m.include?('Test exception message') })
    assert(captured_messages.any? { |m| m.include?('current') })
    assert(captured_messages.any? { |m| m.include?('previous') })
    assert(captured_messages.any? { |m| m.include?('Backtrace') })
  end

  test 'log_render_error handles nil previous content' do
    exception = RuntimeError.new('Test')

    captured_messages = []
    mock_logger = Class.new do
      def initialize(messages_array)
        @messages = messages_array
      end

      def error(msg)
        @messages << msg
      end
    end.new(captured_messages)

    original_logger = Rails.logger
    Rails.logger = mock_logger

    begin
      InvokeRedcarpet.log_render_error(exception, 'current', nil)
    ensure
      Rails.logger = original_logger
    end

    # Should log current content but not crash on nil previous
    assert(captured_messages.any? { |m| m.include?('current') })
    # Should not include "Previous content" line
    assert_not(captured_messages.any? { |m| m.include?('Previous content:') })
  end

  test 'invoke_and_sanitize is thread-safe' do
    # Run multiple threads simultaneously
    threads =
      10.times.map do |i|
        Thread.new do
          10.times do
            result = InvokeRedcarpet.invoke_and_sanitize("*thread #{i}*")
            assert result.include?('thread')
            assert result.html_safe?
          end
        end
      end

    threads.each(&:join)
    # If we get here without crashes, thread safety is working
    assert true
  end
end
