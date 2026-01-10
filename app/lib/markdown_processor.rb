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
  #

  # We do NOT use render.unsafe = true. We use the default (safe mode)
  # which blocks all raw HTML. This is the same behavior as Redcarpet had.
  # We then use fast regex operations to add security attributes to links
  # and strip disallowed URL protocols.
  #
  # When we first switched to Commonmarker we used unsafe: true and
  # a scrubber building on Rails::Html::PermitScrubber.
  # This provided a lot of *great* functionality, because then users
  # could use markdown *and* embed a lot of safe HTML.
  # However, this approach caused a *massive* number of Ruby objects to be
  # created (nodes to represent parts of the HTML), that then needed to
  # be walked with Ruby code. We optimized this, and if the site was
  # rarely visited, it'd be fine. However, even when we optimized
  # this approach, it caused a dramatic
  # spike in 95th percentile average response times (~100ms->~160ms)
  # and caused RSS memory use to go out-of-control. Even aggressive
  # compaction couldn't prevent the system's memory use from
  # growing, running out of memory, and crashing.
  # So we switched to forbidding HTML and using simple regexes when
  # we must handle full markdown.
  #
  COMMONMARKER_OPTIONS = {
    render: {
      escape: true # Escape raw HTML so users can see what they entered (safely)
    },
    extension: {
      autolink: true, # Autolink URLs to simplify references
      tagfilter: true, # Filters out potentially harmful tags like <style>
      strikethrough: true, # Often used alongside GitHub-flavored markdown
      table: true, # Tables can be useful in justification text
    }
  }.freeze

  # Regex to match allowed URL protocols and relative URLs.
  # This allows http:, https:, mailto:, relative paths (/, ./, ../),
  # and anchors (#).
  # This prevents anything else such as javascript:, data:,
  # and other dangerous protocols.
  ALLOWED_MARKDOWN_URL_PATTERN = %r{\A(?:https?:|mailto:|/|\.\.?/|#)}i

  # The following pair of regex patterns are designed to *only* match
  # text (potentially multiple lines) that we KNOW does not require markdown
  # processing, and can instead be directly copied to the user.
  # Critically, for security, these NEVER accept "<" in the input.
  #
  # We do this check as an optimization to ONLY call the markdown
  # processor when it's necessary (as much as we can).
  # Note that we have to check on period and colon specially,
  # because www.foo.com and http://foo.com *do* need to be processed
  # by the markdown processor and they can't just be passed through.
  #
  # It's okay if the text we accept is slightly
  # different from what a markdown generator would generate, as
  # long as it's *visually* the same to end users. E.g., if the processor
  # normalizes some HTML entity to a normal character, but the user can't
  # see the difference, it doesn't matter if we accept it as-is.
  #
  # In our measures of older versions of this pattern (for only 1 line),
  # we matched 83.87% of the justification text.
  # That justifies this as a pretty good optimization that
  # is not *too* hard to read and verify.
  # It's *okay* to pass something to the markdown processor, we just try
  # to ensure that most such requests are actually needed.
  # We save lots of CPU by only working hard when we must do so.
  #
  # EXAMPLES OF IMPORTANT CONSTRAINTS:
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
  #   We do allow a period at the line of a line, because that will work.
  # - Must NOT require HTML escaping, e.g., no "<" or ">".
  #   If we allowed only some cases, like '<i>',
  #   then we would allow imbalanced inputs like `<i>hello`.
  #   We could add special cases, but then users would be confused when the
  #   special cases stopped working because we had to switch to the full
  #   markdown processor.
  # - Must have LIMTED backtracking, as a performance requirement.
  # We define a match for 1 line, then how to match 1+ lines.

  # Match a single line requiring NO markdown processing and that
  # can instead simply be passed through to the user.
  # It rejects numbered lists, un-numbered lists, headings, etc.
  # It *requires* at least one nonspace character (it doesn't match
  # a blank line, which is a paragraph break in markdown).
  # It does NOT match URLs, email addresses, or domain names, and that
  # that means that these characters are special: [./@].
  # For speed, it has almost no backtracking (in rare cases 1-2 chars).
  # We never use this regex directly, we only use MARKDOWN_UNNECESSARY
  # which references it. However, we format it as a regex so
  # that are our tools will know that's how we will use it.
  MARKDOWN_UNNECESSARY_LINE = %r{
    # GUARD: Reject lines that are ONLY blank lines.
    # We could use "$" to mean \n or \z, but that's such a common
    # mistake that it's better to be clear here.
    (?! [\040\t]++(\r?\n|$) )
    # GUARD: Reject possibly-indented table lines beginning with "|",
    # numbered and un-numbered lists, headers, and blockquotes.
    (?! \040{0,3} (?: \| | (?:\d+[.\)]|[*+-]|\#+|>)[\040\t] ) )
    # GUARD: Reject Code Blocks (4+ spaces), HRules (3+ hyphens), and
    # GitHub Flavored Markdown (GFM) No-Outer-Pipe/lazy/simple tables (these
    # must have a second line of the form "--- |" which this will reject).
    (?! \040{4,}|-{3,} )
    # We don't need to guard fenced code blocks like ~~~sh or ```ruby,
    # because we will later exclude backticks (tt) and tildes (strikethrough)
    # from the content characters' safe character set anyway.

    # CONTENT CHARACTERS
    (?:
      # SAFE CHARACTER SET
      # This is the safe character set, which is all but a few characters.
      # For security, the *key* is that "<" is NOT in the safe character set.
      # We omit characters that may have meaning to markdown, e.g.:
      # *italics*, _italics_, ~strikethrough~, `teletype`, [URL link],
      # < > of HTML.
      # Less obvious are &entities-maybe, email@somewhere.com,
      # https://link, www.example.org, https://link again, \-disable
      # Some characters are actually safe unless a guard prevents it, e.g.,
      # hyphen and vertical bar are normally safe and so are allowed here
      # unless a guard forbids it.
      # Note that space and tab are normally safe, and thus allowed.
      # We allow " and ' because we don't use smarty-quotes; if you want
      # curling quotes, use their UTF-8 characters.
      # We exclude \r and \n so this pattern doesn't match across lines.
      # We also exclude \f (form feed), \v (vertical tab), and \0 (null)
      # as these control characters are unusual and could cause issues.
      [^*_~`\[\]<>\&@:\.\/\\\r\n\f\v\0]
      |
      # HTML ENTITIES: Note we allow arbitrary case.
      # &name; OR &#123; (decimal) OR &#xabc; (hexadecimal)
      \&(?: [a-z0-9]++|\#x[0-9a-f]{1,6}|\#[0-9]{1,7} );
      |
      # CONTEXTUAL PUNCTUATION & DOUBLE SLASH:
      # Allows // or certain punctuation ONLY if followed by space, ", or '
      # This allows "Sentence 1. Sentence 2" or "This & that" or "// comment",
      # but not www.example.com or https://example.com.
      # Periods are especially tricky because they can form domain names.
      (?://|[\.\:\&\@]) (?:\040|"|')
      |
      # CONTEXTUAL SINGLE SLASH: Prevent :// and // (unless followed by space)
      # Allowed if followed by letter/digit and NOT preceded by colon.
      # This allows text like "N/A" but not https://example.com
      (?<!\:)\/(?=[\p{L}0-9])
    )++ # Possessive quantifier to ensure maximum performance - no rollback
    # Optional final period. It's at line end, so it can't be a domain name.
    \.?
  }xiu

  # This is the final pattern to determine if markdown is unnecessary.
  # It can match 1+ non-empty lines separated by single newlines.
  # We presume its leading and trailing whitespace have been stripped.
  # In markdown, consecutive lines without blank lines form one paragraph
  # by default (and we're using the default), so multiple lines often
  # don't need markdown processing.
  # We compose this regex from MARKDOWN_UNNECESSARY_LINE to avoid
  # duplication of the specification of a single line.
  #
  # We must NOT match blank lines (two consecutive newlines) as that is
  # a paragraph break in markdown.
  # rubocop:disable Style/RegexpLiteral
  MARKDOWN_UNNECESSARY = %r{
    \A
    #{MARKDOWN_UNNECESSARY_LINE.source}
    (?:\r?\n#{MARKDOWN_UNNECESSARY_LINE.source})*
    \z
  }xiu
  # rubocop:enable Style/RegexpLiteral

  # The following pattern *only* matches simple bare URLs, so that
  # we can handle them specially instead of invoking the markdown processor.
  #
  # This is *primarily* an optimization, so that we can avoid calling
  # the markdown processor unnecessarily. However, it *also* quietly
  # provides "expected functionality". Users often put a single URL into
  # a justification, and they typically don't represent "&" as "amp;"
  # like they're supposed to do in HTML or Markdown. This happens often when
  # users provide a query string in the URL. So by this code, if they
  # *only* provide a URL, any "&" will "do the right thing".
  #
  # To craft this pattern we used a dataset of all justifications. Of them,
  # 66353 didn't match an older version of the "unnecessary" match above.
  # In that "didn't match" set, 28684/66353 (43%) were simple bare URLs.
  # So we've crafted a simple bare URL matcher that matches 26697 of them.
  # That means that 28536/66353 (43%) of the strings not matched by the
  # simple "markdown unnecessary" strings are processed here.
  # That means this catches about (100%-83.87%)*43% = 6.94% more strings, so
  # by adding this measure, we can skip markdown processing about 90.81%
  # (83.87+6.94%) of the time.
  # Basically, by doing a simple check, we can skip more complex markdown
  # processing in the vast majority of cases.
  #
  # Note that this pattern does NOT match dangerous HTML characters like
  # ', ", <, or >. Thus, there's no way to turn accepting these directly
  # into an attack (in particular this counters an XSS attack).
  # This pattern also does NOT match a space character (use %20 in a URL);
  # an internal space would indicate we need more sophisticated processing.
  # This pattern *only* matches simple bare URLs, so if it matches,
  # we know there's no need for more complex markdown parsing.
  #
  # In the name of performance and maintainability we've made simplifications.
  # Some URLs won't match this regex, and that's okay, they'll be handled
  # by the full markdown processor.
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
    (?:\:[0-9]+)?                               # Optional port#
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
    # Using unsafe: false (default), so raw HTML is blocked.
    html = Commonmarker.to_html(content, options: COMMONMARKER_OPTIONS)

    # Strip hrefs with disallowed protocols. Commonmarker always generates
    # double quotes, and users can't use HTML, so we only handle the case
    # that can happen (no need for single-quote code).
    html.gsub!(/<a([^>]*?)href="([^"]*?)"([^>]*)>/m) do
      before = ::Regexp.last_match(1)
      url = ::Regexp.last_match(2)
      after = ::Regexp.last_match(3)

      if url.match?(ALLOWED_MARKDOWN_URL_PATTERN)
        # Valid URL - keep it and add security attributes
        # href comes before rel to match previous behavior
        "<a#{before}href=\"#{url}\" rel=\"nofollow ugc noopener noreferrer\"#{after}>"
      else
        # Strip href attribute - link becomes plain text
        "<a#{before}#{after}>"
      end
    end

    # Mark as html_safe since Commonmarker escapes HTML and we've validated URLs
    html.html_safe
  end
  # rubocop:enable Rails/OutputSafety, Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
