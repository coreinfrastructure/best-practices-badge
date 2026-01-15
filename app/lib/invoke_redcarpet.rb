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
# 1. Always re-instantiate the markdown renderer AND processor instances
# before using them, and thus, each is used only once.
# The *most* likely cause of the occasional crash, by far,
# is "junk" data that was left over from a
# previous execution of the redcarpet markdown processor.
# This assertion requires a size be 0, and its failure indicates it isn't.
# Recreating the markdown renderer and processor for each use is aggressive,
# but doing this has a surprisingly small overhead, as measured
# by the script/benchmark-restart-redcarpet.rb.
# Originally I only re-created the markdown processor instance, since
# that's where the original error reports came from, namely
# `md->work_bufs[BUFFER_SPAN].size == 0`.
# The benchmark indicates that if a project section
# needs 50 markdown renders (an unlikely high number for a project),
# instantiating a processor each time adds 50*(0.104432-0.010429)/10000
# = 0.47 milliseconds (0.00047 seconds) in real time for showing a project.
# However, during testing, we rarely got this non-reproducible message
# on the line that called the `render` method on the processor instance
# even though had been created *solely* for this use:
# NotImplementedError: method 'to_s' called on unexpected
# T_IMEMO object (0x00007fd5c82c83c8 flags=0x8703a)
# app/lib/invoke_redcarpet.rb:245:in 'Redcarpet::Markdown#render'
# The reference to T_IMEMO is surprising; that's a low-level detail that
# simply should never be visible to the test.
# Gemini suggested the following:
# Class variables in Ruby are shared across the inheritance hierarchy
# and persist for the lifetime of the process. In a test environment:
# C-Extension State: The Redcarpet::Markdown object holds a pointer to
# a C-struct representing your RENDERER.
# Memory Reuse: If a test modifies the global state or if the test runner
# (like RSpec or Minitest) interacts with the class in a way that causes
# the Ruby VM to move objects in memory (Compacting GC), a class variable
# pointing to a C-backed object can become "stale."
# The T_IMEMO Connection: The fact that you are seeing a T_IMEMO object
# means that the memory address where the Renderer used to live has been
# reclaimed by the Ruby VM for internal bookkeeping. Because the class
# variable didn't "release" that address, the processor.render call tries
# to execute C-code against an internal VM structure.
#
# It's important that this process reliably work across testing.
# I modified the benchmark to see the overhead of *also* re-creating
# the renderer for each markdown process. If again some project display
# *also* needs 50 markdown renders (an unlikely high number for a project),
# instantiating a markdown processor *and* renderer
# each time adds 50*(0.442712-0.012445)/10000
# = 2.15 milliseconds in real time for showing a project.
# Notice that I'm always using "real" time as the conservative answer.
# Our current "project shows" take around 22msec, so that is a ~10%
# increase in execution time of our most common request type.
# I'm not happy about that. However, this is a worst-case scenario,
# we only call the markdown processor for harder cases, so this isn't
# called very often in practice (and when it is, we usually need it).
#
# It creates a few objects, too. However, if this is what
# we must do to make our application reliable, then that's what we'll do.
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
#
# All of that counters *crashes* but also leads to endless memory growth.
# If we create *one* new markdown processor and renderer *per* transaction,
# they end up scattered across Ruby's memory space and being un-reclaimable.
# So we use heap grooming: we create them in batches.

module InvokeRedcarpet
  require 'redcarpet'

  # Markdown renderer configuration for Redcarpet
  REDCARPET_MARKDOWN_RENDERER_OPTS = {
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true,
    link_attributes: { rel: 'nofollow ugc noopener noreferrer' }
  }.freeze

  REDCARPET_MARKDOWN_PROCESSOR_OPTS = {
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true
  }.freeze

  # To counter memory fragmentation, we allocate markdown objects
  # in batches. We're trying concentrate markdown objects' slots in a
  # few pages, instead of letting them scatter. Each batch will allocate
  # (2 markdown objects + 1 array object)* batch size, plus the queue object,
  # and a slot page can hold 400 objects. We clean up first with GC.start,
  # so a batch will typically fill 1-2 such pages
  # instead of letting them scatter.
  # By concentrating these objects in a few pages,
  # other pages will be able to move.
  MARKDOWN_QUEUE_BATCH_SIZE = 100

  @markdown_queue = Queue.new

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

  # Complain because the processor does not have the expected type
  #
  # @raise [TypeError]
  # @return [void]
  def self.processor_bad_type(p)
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

  # Report markdown stats. GC has a similar function.
  # We'll probably remove this once we're satisfied we've solved
  # memory fragmentation problems.
  def self.report_markdown_info
    # Extract specific stats
    # This extracts only specific class info, so it's faster.
    [Redcarpet::Markdown, Redcarpet::Render::HTML].each do |klass|
      count = 0
      total_mem = 0
      ObjectSpace.each_object(klass) do |o|
        count += 1
        total_mem += ObjectSpace.memsize_of(o)
      end
      Rails.logger.warn "Redcarpet Markdown queue refilled: #{klass.name}: " \
                        "Count #{count}, Ruby-Mem: #{total_mem} bytes"
    end
  end

  # Refill queue of markdown renderer & processor
  # rubocop:disable Metrics/MethodLength
  def self.refill_queue
    # First, clear the deck (this doesn't *compact*)
    Rails.logger.warn("Redcarpet - running GC.start to fill a queue batch size #{MARKDOWN_QUEUE_BATCH_SIZE}")
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # The "Stop the World" pause happens here
    GC.start(full_mark: true, immediate_sweep: true)
    # Calculate elapsed time
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration_ms = ((end_time - start_time) * 1000).round(2)
    Rails.logger.warn("Redcarpet - running GC.start took #{duration_ms}ms ")

    # Use a simple loop to minimize creating intermediate Enumerator objects
    i = 0
    while i < MARKDOWN_QUEUE_BATCH_SIZE
      renderer = Redcarpet::Render::HTML.new(REDCARPET_MARKDOWN_RENDERER_OPTS)
      processor = Redcarpet::Markdown.new(renderer,
                                          REDCARPET_MARKDOWN_PROCESSOR_OPTS)
      # We queue the processor and renderer together, to ensure they're
      # used together. If we discard the renderer without discarding the
      # processor, the internal link from the processor could cause a crash
      @markdown_queue << [processor, renderer]
      i += 1
    end
    report_markdown_info
  end
  # rubocop:enable Metrics/MethodLength

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
    # This is probably over-protective; we'll probably reduce this once
    # we're confident other problems are solved, but until everything works
    # well, we want to eliminate threading as a potential issue.
    $redcarpet_mutex.synchronize do
      # If we're out of pre-created processors and renderers, get a new batch
      refill_queue if @markdown_queue.empty?

      # Use a new markdown renderer and processor on *each* use,
      # so we *know* it has pristine state. We'll presume that there's
      # one available since we just refilled it.
      # Rubocop is *correctly* pointing out that we never use the
      # "renderer" value. What rubocop *cannot* know is that the processor's
      # C implementation has an internal pointer to the renderer object.
      # We *ensure* that the renderer never disappears, while the processor
      # object is alive, by assigning the renderer to a Ruby variable.
      # When this method ends, both will no longer be referenced and never
      # be used again.
      # rubocop:disable Lint/UselessAssignment
      processor, renderer = @markdown_queue.pop
      # rubocop:enable Lint/UselessAssignment

      # For testing: inject a bad type to test type checking
      processor = [] if force_bad_type

      # Check processor type (catches some Rails class reloading issues)
      # Warning: Rails class reloading can invalidate cached instances,
      # causing "wrong argument type"
      # errors even though is_a? checks pass against stale class definitions
      processor_bad_type(processor) unless processor.is_a?(Redcarpet::Markdown)

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
