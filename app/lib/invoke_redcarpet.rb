# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Invoke the Redcarpet markdown processor with thread safety

# We've used redcarpet for years; it's capable, fast, and doesn't
# fragment memory. However, we've recently seen it crash with report,
# which may simply be because we're stressing it more:
# md->work_bufs[BUFFER_SPAN].size == 0
# We thought it was thread-related at first, but using a mutex to ensure
# there was only one, and even having separate instances for a current thread,
# did not make the problem completely go away.
# This issue may be related, it has the error report:
# https://github.com/vmg/redcarpet/issues/570

module InvokeRedcarpet
  require 'redcarpet'

  # Markdown renderer configuration for Redcarpet
  REDCARPET_MARKDOWN_RENDERER_OPTIONS = {
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true,
    link_attributes: { rel: 'nofollow ugc noopener noreferrer' }
  }.freeze

  REDCARPET_MARKDOWN_PROCESSOR_OPTIONS = {
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true
  }.freeze

  # Mutex to ensure thread safety.
  # Redcarpet's C code is not thread-safe, so we use a mutex to ensure
  # only one thread can use the processor at a time.
  # We use a global variable because module constants are cleared on reload
  # in dev/test environments, but this mutex MUST persist across reloads
  # to maintain thread safety.
  # rubocop:disable Style/GlobalVars
  $redcarpet_mutex ||= Mutex.new
  # rubocop:enable Style/GlobalVars

  # The shared Redcarpet processor instance.
  # We create one instance and protect it with a mutex rather than using
  # thread-local storage, as thread-local storage did not provide
  # performance benefits.
  @redcarpet_processor = nil

  # Store the previous content for diagnostic logging
  @previous_content = nil

  # Create a new Redcarpet processor instance
  #
  # @return [Redcarpet::Markdown] A new Redcarpet processor
  def self.create_processor
    renderer = Redcarpet::Render::HTML.new(REDCARPET_MARKDOWN_RENDERER_OPTIONS)
    Redcarpet::Markdown.new(renderer, REDCARPET_MARKDOWN_PROCESSOR_OPTIONS)
  end

  # Ensure the processor is initialized
  # This is a separate method to make the initialization explicit and testable
  #
  # @return [void]
  def self.ensure_processor_initialized
    return if @redcarpet_processor

    @redcarpet_processor = create_processor
  end

  # Check that the processor has the expected type
  # Rails class reloading can invalidate cached instances, causing "wrong argument type"
  # errors even though is_a? checks pass against stale class definitions
  #
  # @raise [TypeError] if processor has unexpected type
  # @return [void]
  def self.check_processor_type
    return if @redcarpet_processor.is_a?(Redcarpet::Markdown)

    # Unexpected type - log error and reset
    actual_type = @redcarpet_processor.class
    Rails.logger.error(
      "Redcarpet processor has unexpected type: #{actual_type} " \
      '(expected Redcarpet::Markdown)'
    )
    @redcarpet_processor = nil
    raise TypeError, "Redcarpet processor has wrong type: #{actual_type}"
  end

  # Log a render error with diagnostic information
  #
  # @param exception [Exception] The exception that occurred
  # @param current_content [String] The content being rendered when error occurred
  # @param previous_content [String, nil] The previously rendered content
  # @return [void]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.log_render_error(exception, current_content, previous_content)
    Rails.logger.error(
      "Redcarpet render failed: #{exception.class} - #{exception.message}"
    )
    Rails.logger.error(
      "Current content (#{current_content.to_s.length} chars): " \
      "#{current_content.to_s[0..200].inspect}"
    )
    if previous_content
      Rails.logger.error(
        "Previous content (#{previous_content.to_s.length} chars): " \
        "#{previous_content.to_s[0..200].inspect}"
      )
    end
    return unless exception.backtrace

    Rails.logger.error("Backtrace: #{exception.backtrace.first(5).join("\n  ")}")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Invoke Redcarpet to render markdown content with comprehensive error handling
  #
  # This method wraps the Redcarpet call in exception handling to catch:
  # - C assertion failures (md->work_bufs[BUFFER_SPAN].size == 0)
  # - "wrong argument type" errors from Rails class reloading
  # - Any other unexpected exceptions
  #
  # On error, it logs diagnostic info and either returns HTML-escaped content
  # or re-raises the exception (for testing).
  #
  # @param content [String] The content to render as Markdown
  # @param raise_on_error [Boolean] If true, re-raise exceptions instead of
  #   returning escaped content (for testing)
  # @param force_exception [Exception, nil] For testing: inject an exception
  # @param force_bad_type [Boolean] For testing: inject a bad processor type
  # @return [ActiveSupport::SafeBuffer] HTML-safe rendered output
  #
  # rubocop:disable Rails/OutputSafety, Style/GlobalVars, Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.invoke_and_sanitize(
    content,
    raise_on_error: false,
    force_exception: nil,
    force_bad_type: false
  )
    # Use mutex to ensure only one thread uses Redcarpet at a time
    $redcarpet_mutex.synchronize do
      # For testing: inject a bad type to test type checking
      @redcarpet_processor = [] if force_bad_type

      # Ensure processor is initialized (separate call for clarity)
      ensure_processor_initialized

      # Check processor type (catches Rails class reloading issues)
      check_processor_type

      # For testing: inject an exception to test exception handling
      raise force_exception if force_exception

      # Defensive measure: ensure content is a string
      content_str = content.to_s

      # Try to render the markdown
      result = @redcarpet_processor.render(content_str)

      # Success! Store this content for next error's diagnostic
      @previous_content = content_str

      result.html_safe
    rescue StandardError => e
      # Log comprehensive diagnostic information
      log_render_error(e, content, @previous_content)

      # Reset processor so next call gets a fresh instance
      @redcarpet_processor = nil

      # Either re-raise (for testing) or return escaped content (for production)
      raise if raise_on_error

      # Return HTML-escaped content as fallback
      # Not perfect, but provides safe output to caller
      ERB::Util.html_escape(content.to_s).html_safe
    end
  end
  # rubocop:enable Rails/OutputSafety, Style/GlobalVars, Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
