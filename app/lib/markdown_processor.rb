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
      # Scrub the HTML. This is iterated inside the generated string,
      # so we need to make this efficient.

      # OPTIMIZATION: Short-circuit for non-anchor tags.
      # The only thing we specially manipulate are <a> tags.
      # If what we've received is not a link,
      # execute C-logic (super) and return immediately.
      # This saves 50-60% of Ruby execution for formatting tags
      # like <p>, <b>, etc.
      return super if node.name != 'a'

      # At this point we have an <a> tag

      # Return STOP if super == STOP. This is trivial code, but it's
      # important, and the *reason* it's important requires some explanation.
      # When you call super inside the scrub method of a class inheriting
      # from PermitScrubber, you are asking the parent class to run its
      # own validation logic first.
      # The PermitScrubber parent class checks two things:
      # - Is the tag name (e.g., <a>) in the self.tags allow-list?
      # - Are the attributes on that tag (e.g., href, onclick)
      #   in the self.attributes allow-list?
      # If either of these checks fails, super returns the constant STOP.
      # By including the statement below, we are saying:
      # "If the standard Rails security check already decided this node
      # is illegal, stop immediately and do not process my custom
      # link-hardening logic."
      # Without this line, the code would contain a subtle but dangerous
      # logic flaw, because it could override the STOP we already received.
      # Basically, if an <a> tag with a forbidden attribute
      # submits a link with a forbidden attribute that
      # rails-html-sanitizer usually strips
      # for security (like a style attribute or an event handler
      # like onmouseover), without the return STOP line, then
      # node.name != 'a' is false (it is an anchor), so
      # super runs. It sees the forbidden attribute and marks the node
      # for deletion/scrubbing by returning STOP.
      # But without the following line, the code we have added would
      # ignore that result. It would instead continue to the next lines
      # to perform other protocol checks and processing and ends, implicitly
      # returning the result of the last line evaluated (or CONTINUE).
      # As result, the code would have accidentally overridden the
      # STOP signal from the parent class. The "Illegal" tag would
      # now be treated as safe because the custom logic finished
      # without respecting the parent's STOP objection.
      return STOP if super == STOP

      # At this point we have an <a> tag with no other objections

      # Inject security and SEO attributes
      node['rel'] = 'nofollow ugc noopener noreferrer'

      # Fast protocol check: avoid URI.parse for relative links (no ':')
      if (href = node['href']).present? && href.include?(':')
        begin
          scheme = URI.parse(href).scheme
          # Remove href if the protocol is not in our whitelist
          node.remove_attribute('href') if ALLOWED_PROTOCOLS.exclude?(scheme&.downcase)
        rescue URI::InvalidURIError # We can't parse the href; remove it
          node.remove_attribute('href')
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
  #
  # This pattern matches text that we KNOW does not require markdown processing.
  # We do this check as an optimization to skip calling the markdown
  # processor in most cases when it's clearly unnecessary.
  # In particular, note that we have to handle period and colon specially,
  # because www.foo.com and http://foo.com *do* need to be processed
  # differently and can't just be passed through.
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

  # The following pattern *only* matches simple bare URLs, so that
  # we can handle them specially instead of invoking the markdown processor.
  # To craft this pattern we used a dataset of all justifications. Of htem,
  # 66353 didn't match an older version of the "unnecessary" match.
  # Of that didn't match set, 28684/66353 (43%) were simple bare URLs.
  # So we've crafted a simple bare URL matcher that matches 26697 of them.
  # That means that 28536/66353 (43%) of the strings not matched by the
  # simple "markdown unnecessary" strings get caught here.
  # That means this catches about (100%-83.87%)*43% = 6.94% more strings, so
  # by adding this measure, we can skip markdown processing about 90.81%
  # (83.87+6.94%) of the time.
  # Basically, by doing a simple check, we can skip the more complex markdown
  # processing in the vast majority of cases.
  #
  # Note that this pattern does NOT match dangerous HTML characters like
  # ', ", <, or >. Thus, there's no way to turn accepting these directly
  # into an attack (in particular this counters an XSS attack).
  # This pattern also does NOT match a space character (use %20 in a URL);
  # an interal space would indicate we need more sophisticated processing.
  # This pattern *only* matches simple bare URLs, so if it matches,
  # we know there's no need for more complex markdown parsing.
  #
  # In the name of performance and maintainability we've made simplifications.
  # Some URLs won't match this regex, and that's okay, they'll be handled
  # by the full markdown processor.
  # For example, it doesn't match on port numbers,
  # which are exceeding rare in our data set.
  # It doesn't accept domain "localhost", which make no sense for us.
  # We *will* match a few strings that strictly speaking aren't valid URLs,
  # but those won't hurt us security-wise:
  # 1. This regex permits domains that
  # aren't legal DNS names because they have domain labels that are
  # (a) too long or (b) begin/end in "-".
  # We *could* address that, but doing that would create a regex that's
  # more complex and would do some backtracking.
  # 2. The query string is a little too generous. However, we really
  # don't need to parse the query string to break into components;
  # we just want to know if it generally meets the format of a URL
  # and can't be turned into an attack. More than that is a waste.
  #
  # Our goal is to quickly match on common cases and always prevent attacks.
  # The regex given here never backtracks, so it's fast.
  # The regex never permits injection attacks like XSS.
  # If a user puts a garbage URL in, it'll create a garbage link.
  # Garbage in, garbage out, but it won't be a *security* problem because
  # there's no attack that such a malformed string would lead to.

  SIMPLE_URL_REGEX = %r{
    \A
    https?://                                   # Protocol
    [a-z0-9-]+                                  # First DNS label (simplified)
    (?:\.[a-z0-9-]+)+                           # Subsequent labels (simplified)
    (?:/                                        # Optional path w/dirs and %xx
      (?:[a-z0-9\-._~:@!$&()*+,;=/]|%[0-9a-f]{2})*
    )?
    (?:\?                                       # Query String
      (?:[a-z0-9\-._~:@!$&()*+,;=/]|%[0-9a-f]{2})*
    )?
    (?:\#[a-z0-9\-._~:@!$&()*+,;=%]*)?          # Optional anchor
    \z
  }ix

  # The HTML prefix & suffix generated by the markdown processor.
  # When we shortcut the markdown processor, we need to insert these
  # to have the same result.

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

    # Skip markdown processing for simple bare URLs, and instead generate
    # their markdown directly. We are escaping the HTML because "&" must
    # be escaped anywhere in HTML when not followed by space, even in an href,
    # yet "&" is the form separator character in
    # query strings for multiple fields so we need to support that character.
    # It's safer to use escapeHTML anyway, even if we didn't allow "&".
    if content.match?(SIMPLE_URL_REGEX)
      escaped_url = CGI.escapeHTML(content) # Escape URL for use in HTML
      # Note that C Ruby turns the following into one single final string
      # allocation, and *not* the multiple intermediate allocations you
      # might expect. The VM sees this as one sequence of:
      # putself (get prefix)
      # putobject (literal fragment)
      # putself (get url)
      # topn ... concatstrings
      return "#{MARKDOWN_PREFIX}<a href=\"#{escaped_url}\"" \
             ' rel="nofollow ugc noopener noreferrer">' \
             "#{escaped_url}</a>#{MARKDOWN_SUFFIX}".html_safe
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
