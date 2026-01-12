# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Invoke the Redcarpet markdown processor with thread safety

# We've used redcarpet for years; it's capable, fast, and doesn't
# fragment memory. However, we've recently seen it crash with report,
# which may simply be because we're stressing it more:
# md->work_bufs[BUFFER_SPAN].size == 0
# We throught it thread-related at first, but using a mutex to ensure
# there was only one, and even having separate instances for a current thread,
# did not make the problem go away.
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
  # We use ||= to ensure the mutex is not replaced if the module is reloaded.
  REDCARPET_MUTEX = (defined?(REDCARPET_MUTEX) ? REDCARPET_MUTEX : Mutex.new)

  # The shared Redcarpet processor instance.
  # We create one instance and protect it with a mutex rather than using
  # thread-local storage, as thread-local storage did not provide
  # performance benefits.
  @redcarpet_processor = nil

  # Get or create the Redcarpet processor instance
  #
  # @return [Redcarpet::Markdown] The Redcarpet processor
  def self.redcarpet_processor
    @redcarpet_processor ||=
      begin
        renderer = Redcarpet::Render::HTML.new(REDCARPET_MARKDOWN_RENDERER_OPTIONS)
        Redcarpet::Markdown.new(renderer, REDCARPET_MARKDOWN_PROCESSOR_OPTIONS)
      end
  end

  # Invoke Redcarpet to render markdown content
  #
  # @param content [String] The content to render as Markdown
  # @return [ActiveSupport::SafeBuffer] HTML-safe rendered output
  #
  # rubocop:disable Rails/OutputSafety
  def self.invoke_and_sanitize(content)
    # Use mutex to ensure only one thread uses Redcarpet at a time
    REDCARPET_MUTEX.synchronize do
      # Defensive measure: ensure content is a string.
      # Strings return themselves, so it should have no performance impact.
      redcarpet_processor.render(content.to_s).html_safe
    end
  end
  # rubocop:enable Rails/OutputSafety
end
