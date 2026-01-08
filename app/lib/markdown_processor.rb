# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Perform markdown processing in a secure and performant way

# rubocop:disable Metrics/ModuleLength
module MarkdownProcessor
  require 'commonmarker'

  # Configuration Constants
  # Pre-frozen to minimize per-call allocations.

  # We once used Redcarpet to process markdown, but it became
  # unreliable as we began using it a lot.
  # So we switched to Commonmarker, a different markdown processor that
  # supports a somewhat similar but not identical set of options.
  #
  # Here are the old Redcarpet Markdown renderer configuration:
  # REDCARPET_MARKDOWN_RENDERER_OPTIONS = {
  #   filter_html: true, no_images: true,
  #   no_styles: true, safe_links_only: true,
  #   link_attributes: { rel: 'nofollow ugc' }
  # }.freeze
  # REDCARPET_MARKDOWN_PROCESSOR_OPTIONS = {
  #   no_intra_emphasis: true, autolink: true,
  #   space_after_headers: true, fenced_code_blocks: true
  # }.freeze
  #
  # Note in particular that adding rel='nofollow ugc' isn't directly
  # supported by Commonmarker, and that's important,
  # because if we don't add that, attackers will want to add garbage
  # to improve some site's SEO. So we must supplement Commonmarker
  # with a sanitizer to use it in our context.

  # It may appear odd that we're using render.unsafe = true, but that's because
  # Commonmarker doesn't allow us to directly control exactly what is and
  # is not allowed to be rendered. We'll instead do a
  # separate safety pass afterwards to permit and forbid specific items.
  # This is the "normal way" to do such processing.
  COMMONMARKER_OPTIONS = {
    render: {
      unsafe: true # Sanitizer handles the safety; this just provides the HTML
    },
    extension: {
      autolink: true, # Autolink URLs to simplify references
      tagfilter: true, # Filters out potentially harmful tags like <style>
      strikethrough: true, # Often used alongside GitHub-flavored markdown
      table: true, # Tables can be useful in justification text
    }
  }.freeze

  # Allowed protocols; Set tends to be faster than Array for .include? checks
  ALLOWED_PROTOCOLS = Set.new(%w[http https mailto]).freeze

  # Pre-computed lists for the scrubber

  # FORBIDDEN TAGS: Start with a "safe" list & remove even more.
  # Strip media, because if we strip direct media references,
  # some attackers will be less interested in messing with this system.
  # We strip the summary and details tags because they
  # can hide important information. We *do* allow tables.
  HARDENED_TAGS = (Rails::Html::SafeListSanitizer.allowed_tags -
                  %w[img video audio details summary]).freeze

  # FORBIDDEN ATTRIBUTES: Start with "safe" list but strip more:
  # - target (there's an HTML attack).
  # - class and id (these can manipulate the display)
  HARDENED_ATTRS = (Rails::Html::SafeListSanitizer.allowed_attributes -
                   %w[class id target] + %w[rel]).freeze

  class HardenedScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = HARDENED_TAGS
      self.attributes = HARDENED_ATTRS
    end

    # rubocop:disable Metrics/MethodLength
    def scrub(node)
      return STOP if super == STOP

      if node.name == 'a'
        # Inject security/SEO attributes
        # node['attr'] = val is an allocation, but required for the mutation
        node['rel'] = 'nofollow ugc noopener noreferrer'

        if (href = node['href']).present?
          begin
            # Optimization: only parse URI if it contains a scheme separator
            if href.include?(':')
              scheme = URI.parse(href).scheme
              # Set.include? is O(1) vs Array.include? which is O(n)
              node.remove_attribute('href') if ALLOWED_PROTOCOLS.exclude?(scheme&.downcase)
            end
          rescue URI::InvalidURIError
            node.remove_attribute('href')
          end
        end
      end

      CONTINUE
    end
    # rubocop:enable Metrics/MethodLength
  end

  # PRE-INSTANTIATED SINGLETONS
  # These are created ONCE and reused for every single request.
  SANITIZER = Rails::Html::SafeListSanitizer.new
  SCRUBBER  = HardenedScrubber.new

  # The following pattern is designed to *only* match
  # a line that we KNOW cannot require markdown processing.
  # MODIFY THIS PATTERN TO TEST!
  #
  # This pattern matches text that we KNOW does not require markdown processing.
  # We do this check as an optimization to skip calling the markdown
  # processor in most cases when it's clearly unnecessary.
  # In particular, note that we have to handle period and colon specially,
  # because www.foo.com and http://foo.com *do* need to be processed
  # as markdown.
  #
  # In our measures this matches 83.87% of the justification text in our system.
  # That's a pretty good optimization that is not *too* hard to read and verify.
  # It's *okay* to pass something to the markdown processor, we just try
  # to ensure that most such requests are needed.
  #
  # IMPORTANT CONSTRAINTS:
  # - Must NOT match numbered lists (e.g., "1. Item")
  #   markdown formats them as <ol><li>.
  # - Must NOT match un-numbered lists (e.g., "* Item")
  # - Must NOT match headings ("# foo")
  # - Must NOT match URLs (e.g., "https://github.com/foo") because
  #   markdown auto-links them (autolink: true option).
  # - Must NOT match implied domain names like www.foo.com or email addresses.
  #   (autolink: true option).
  #   We avoid matching possible domain names and URLs and email addresses
  #   by only allowing a period or colon if it's followed by a space, and
  #   only allowing "/" if it's followed by an alphanumeric or a "slash space".
  #   We also don't accept "@".
  # - Must NOT require HTML escaping, e.g., no "<" or ">".
  #   If we allowed '<i>' then we would allow imbalanced inputs like
  #   `<i>hello`; the full markdown processor can handle such cases.
  #   We can allow "&" followed by a space, as modern HTML knows that *can't*
  #   be an entity. We can allow single-quotes and double-quotes since
  #   this is not in an attribute and we aren't implementing smarty quotes.

  MARKDOWN_UNNECESSARY = %r{\A
    (?!(\d+\.|\-|\*|\+|\#+)\s) # numbered lists, un-numbered lists, headings
    (?!\-\-\-) # Horizontal lines
    ([A-Za-z0-9\040\,\;\'\"\!\(\)\-\?\%\+]|
     \.\040|\:\040|\&\040|/(/\040|[A-Za-z0-9]))+
    \.? # Optional final period
    \z}x

  MARKDOWN_PREFIX = '<p>'
  MARKDOWN_SUFFIX = "</p>\n"

  # Render markdown content to HTML - main entry point.
  # Usage: MarkdownProcessor.render(content)
  #
  # For simple text with no markdown syntax, we bypass complex
  # processing entirely for performance.
  #
  # @param content [String] The content to render as Markdown
  # @return [ActiveSupport::SafeBuffer] HTML-safe rendered output
  #
  # We have to disable Rails/OutputSafety because Rubocop can't do the
  # advanced reasoning needed to determine this isn't vulnerable to CSS.
  # The MARKDOWN_UNNECESSARY pattern doesn't match "<" etc.
  # The markdown + sanitizer process is configured to output safe strings.
  # rubocop:disable Rails/OutputSafety, Metrics/MethodLength
  def self.render(content)
    # Return empty string if content is blank.
    # Ruby always returns the exact same empty string object (per object_id)
    # if it's asked to return a literal empty string from a source file
    # with `frozen_string_literal: true`.
    # So this next line *never* allocates a new object, even though it
    # *appears* that it might.
    return '' if content.blank?

    # Strip away leading/trailing whitespace. This makes it easier for
    # us to detect numbered lists, etc. Leading and trailing space
    # doesn't really make any sense in this context. The .to_s is
    # defensive; normally it won't do anything other
    # than return what was passed.
    content = content.to_s.strip

    # Skip markdown processing for simple text with no markdown syntax
    # and no way to generate dangerous code (e.g., no < or >).
    # At one time we called html_escape, but that is completely unnecessary
    # because MARKDOWN_UNNECESSARY won't let those sequences in, and
    # removing the unnecessary call helps us avoid unnecessary work and
    # unnecessary string allocation. We concatenate all at once to
    # avoid creating unnecessary temporary strings as intermediaries.
    # We declare the result as html_safe so that views can more efficiently
    # use the result.
    if content.match?(MARKDOWN_UNNECESSARY)
      return "#{MARKDOWN_PREFIX}#{content}#{MARKDOWN_SUFFIX}".html_safe
    end

    # Apply more sophisticated markdown processing.
    # Commonmarker releases the GVL here for thread-safe parallel execution
    raw_html = Commonmarker.to_html(content, options: COMMONMARKER_OPTIONS)

    # Sanitize and scrub in a single pass
    # Thanks to this process we can mark it as html_safe.
    SANITIZER.sanitize(raw_html, scrubber: SCRUBBER).html_safe
  end
  # rubocop:enable Rails/OutputSafety, Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
