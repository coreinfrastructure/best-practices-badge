# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Invoke the Redcarpet markdown processor with *MAXIMIZED* safety

# We've used redcarpet for years. It's capable, fast, and doesn't
# fragment memory. However, we've recently seen it crash every once in a while
# with this report, which may simply be because we're stressing it more:
# md->work_bufs[BUFFER_SPAN].size == 0
# This issue may be related, it has the error report:
# https://github.com/vmg/redcarpet/issues/570

# This failure is rare and we've been unable to replicate it
# at this time. We're open to switching. Commonmarker is really good, but
# when we tried to switch to it, its use led to uncontrolled memory growth
# we couldn't accept. A pure-Ruby solution can't work for us,
# we have to support too many requests.

# So instead, this module implements the following countermeasures
# to prevent problems:
#
# 1. Always re-instantiate the markdown processor instance before using it.
# The *most* likely cause of the occasional crash, by far,
# is "junk" data that was left over from a
# previous execution of the redcarpet markdown processor.
# This assertion requires a size be 0, and its failure indicates it isn't.
# Recreating the markdown processor for each use is aggressive, but
# doing this has a surprisingly small overhead. My script
# script/benchmark-restart-redcarpet.rb indicates that if a project section
# needs 50 markdown renders (an unlikely high number for a project),
# instantiating a processor each time adds 50*(0.104432-0.010429)/10000
# = 0.47 milliseconds (0.00047 seconds) in real time for showing a project.
# It also creates a few objects. This is overhead, but this is an absurdly
# small fraction of overall per-request effort. If this is what
# we must do to make our application reliable, then that's what we'll do.
# There's no obvious reason to re-create the renderer, as that merely has
# static information that doesn't depend on the data. So we only
# re-instantiate the markdown processor each time.
#
# 2. Use a mutex to force redcarpet markdown processing into single-thread use.
# This is probably unnecessary given point 1. However, since threading is
# a common mistake in low-level code, by using a mutex we can
# completely eliminate this as a possible cause. This does mean that threads
# will need to take turns using this, but each one doesn't take much time,
# and other threads will have a turn on release, so this seems acceptable.
#
# 3. Catch exceptions, and return an escaped version. We don't expect
# that to catch C assertion failures, but it doesn't hurt to catch
# other problems just in case they occur. We also log any exceptions we
# catch, in case that helps find problems.
#
# All this overhead isn't *quite* as bad as it seems when you realize that
# most markdown texts aren't sent to this routine anyway.
# We separately handle blank text, URL-only text, and
# "simple" text that doesn't require markdown processing. So only some
# tests end up requiring the full processor.
#
# Given the info we have, we think the problem is left-over uncleared data,
# so our aggressive approach should *completely* eliminate this problem.
#
# None of these aggressive countermeasures can prevent problems if some
# specific input can cause an *immediate* crash/vulnerability.
# However, I think that's quite unlikely, for 2 reasons.
#
# First, we performed focused fuzz testing on the
# processor.render(content_str) call, with many efforts. I couldn't find
# *any* inputs that could produce a problem in one shot.
# It's true that fuzzing can't guarantee finding a problem, but at least
# it provides evidence of no further problems.
#
# Second, the assertion failure we see is an assertion about
# the state of the processor *itself* that, in our use case, cannot
# happen if we re-create the processor each time.
# Note: redcarpet is a wrapper around the "sundown" parser:
# https://cocoapods.org/pods/sundown
# I asked Google Gemini to analyze the source code for this circumstance.
# It determined that:
#
# Based on the source code of the underlying C library (Sundown,
# wrapped by Redcarpet), the answer is yes: this specific assertion is a
# "pre-flight" check that occurs at the very beginning of the rendering
# process.
# If you re-instantiate the processor for every call, you effectively
# bypass the conditions that lead to this crash.
# 1. Reasoning: The "Pre-flight" Check
# The function sd_markdown_render is the main entry point for the
# C-level parser. The assertion assert(md->work_bufs[BUFFER_SPAN].size ==
# 0) is located at the top of this function.
# Its purpose is to ensure that the Span Buffer—a temporary stack used
# to parse inline elements like *italics* or [links]—is completely empty
# before starting. If the size is not zero, it means a previous rendering
# operation was interrupted or had a logic bug that left "garbage" in
# the buffer.
# When it crashes: It crashes the moment you call .render(text), before
# a single character of the new text has been processed.
# Why Re-instantiation works: When you call Redcarpet::Markdown.new,
# the C code allocates a brand-new sd_markdown struct and initializes
# all buffer sizes to 0. Even if a previous input was "malicious" or
# "corrupting," that corruption lived in the memory of the old object. By
# discarding the old object, you discard the corruption.
# 2. Can a single input cause a crash mid-way?
# With this specific assertion, no. Because it is at the entry point of
# the render function, it only checks the state inherited from the last
# time that specific object was used.
# The only way a "single input" could trigger this in a fresh object is if
# you were using recursion -- for example, if a custom renderer's callback
# (like block_code) called markdown.render again using the same processor
# instance. In that case, the second (nested) call would see that the first
# call is currently using the Span Buffer and would trigger the assertion.
# 3. Source Code Reference
# You can review the logic in the official Redcarpet GitHub
# repository. Note that line numbers may shift slightly between versions,
# but the logic remains in the sd_markdown_render function.
# Source URL: vmg/redcarpet - ext/redcarpet/markdown.c
# The specific code block looks like this:
# C
# void
# sd_markdown_render(struct buf *ob, const uint8_t *document, size_t doc_size, struct sd_markdown *md)
# {
#    // ... initialization code ...
#    /* check that the buffers are empty */
#    assert(md->work_bufs[BUFFER_SPAN].size == 0);
#    assert(md->work_bufs[BUFFER_DIFF].size == 0);
#    // ... parsing begins after these checks ...
# }

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

  RENDERER = Redcarpet::Render::HTML.new(REDCARPET_MARKDOWN_RENDERER_OPTIONS)

  # Mutex to ensure thread safety.
  # Redcarpet's C code is not thread-safe, so we use a mutex to ensure
  # only one thread can use the processor at a time.
  # We use a global variable because module constants are cleared on reload
  # in dev/test environments, but this mutex MUST persist across reloads
  # to maintain thread safety.
  # rubocop:disable Style/GlobalVars
  $redcarpet_mutex ||= Mutex.new
  # rubocop:enable Style/GlobalVars

  # Store the previous content for diagnostic logging
  @previous_content = nil

  # Check that the processor has the expected type
  # Rails class reloading can invalidate cached instances, causing "wrong argument type"
  # errors even though is_a? checks pass against stale class definitions
  #
  # @raise [TypeError] if processor has unexpected type
  # @return [void]
  def self.check_processor_type(p)
    return if p.is_a?(Redcarpet::Markdown) # Expected type

    # Unexpected type - log error and reset
    actual_type = p.class
    Rails.logger.error(
      "Redcarpet processor has unexpected type: #{actual_type} " \
      '(expected Redcarpet::Markdown)'
    )
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
      "Redcarpet current content (#{current_content.to_s.length} chars): " \
      "#{current_content.to_s[0..1000].inspect}"
    )
    if previous_content
      Rails.logger.error(
        "Redcarpet previous content (#{previous_content.to_s.length} chars): " \
        "#{previous_content.to_s[0..1000].inspect}"
      )
    end
    return unless exception.backtrace

    Rails.logger.error("Redcarpet backtrace: #{exception.backtrace.first(5).join("\n  ")}")
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Invoke Redcarpet to render markdown content with comprehensive error handling
  #
  # This method wraps the Redcarpet call in defensive measures.
  # On error, it logs diagnostic info and either returns HTML-escaped content
  # or re-raises the exception (for testing).
  #
  # @param content [String] The content to render as Markdown
  # @param raise_on_error [Boolean] If true, re-raise exceptions instead of
  #   returning escaped content (for testing)
  # @param force_exception [Exception, nil] For testing: inject an exception
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
      # Recreate markdown processor on *each* use, so *know* it
      # has pristine state.
      processor = Redcarpet::Markdown.new(RENDERER,
                                          REDCARPET_MARKDOWN_PROCESSOR_OPTIONS)

      # For testing: inject a bad type to test type checking
      processor = [] if force_bad_type

      # Check processor type (catches Rails class reloading issues)
      check_processor_type(processor)

      # Defensive measure: ensure content is a string
      content_str = content.to_s

      # For testing: inject an exception to test exception handling
      raise force_exception if force_exception

      # Try to render the markdown
      result = processor.render(content_str)

      # Success! Store this content for next error's diagnostic
      @previous_content = content_str

      result.html_safe
    rescue StandardError => e
      # Log comprehensive diagnostic information
      log_render_error(e, content, @previous_content)

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
