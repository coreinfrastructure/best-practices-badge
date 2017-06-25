# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class TranslationsTest < ActiveSupport::TestCase
  test 'Translations.for_js should not have nil values' do
    assert_equal '', key_with_nil_value(Translations.for_js)
  end

  test 'Translations.for_js has same keys as projects.misc.in_javascript' do
    I18n.available_locales.each do |l|
      assert_equal I18n.t('.projects.misc.in_javascript').keys.sort,
                   Translations.for_js[l].keys.sort
    end
  end

  # What tags & attributes are allowed?
  ACCEPTABLE_TAGS = %w[h1 a strong em i b small tt ol ul li br p span].freeze
  # Class can cause trouble, but we need it for glyphicons, etc.
  ACCEPTABLE_ATTRS = %w[href name class target].freeze

  def sanitize_html(text)
    html_sanitizer = Rails::Html::WhiteListSanitizer.new
    html_sanitizer.sanitize(
      text, tags: ACCEPTABLE_TAGS,
            attributes: ACCEPTABLE_ATTRS
    ).to_s
  end

  def regularize_html(text)
    regularizer = Rails::Html::TargetScrubber.new
    Loofah.fragment(text).scrub!(regularizer).to_s
  end

  # Return true if x is a "simple" (non-compound) non-string type
  def simple_type(x)
    x.is_a?(Symbol) || x.is_a?(Numeric) || x.in?([true, false, nil]) ||
      x.is_a?(Proc)
  end

  # Is the HTML string acceptable?  It needs to NOT have common mistakes,
  # *and* have only the permitted HTML tags & attributes.
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def acceptable_html_string(text)
    return true unless text.include?('<') # Can't be a problem, no '<'

    # First, detect common mistakes.
    # Require HTML tags to start in a lowercase Latin letter.
    # This is in part a regression test; it prevents </a> where "a"
    # is the Cyrillic letter instead of the Latin letter.
    # HTML doesn't care about upper vs. lower case,
    # but it's better to be consistent, and there's a minor
    # compression advantage as described here:
    # http://www.websiteoptimization.com/speed/tweak/lowercase/
    return false if %r{<[^a-z\/]}.match?(text) || %r{<\/[^a-z]}.match?(text)
    return false if text.include?('href = ') || text.include?('class = ')
    return false if text.include?('target = ')
    return false if /(href|class|target)=[^"']/.match?(text)

    # Now ensure that the HTML only has the tags and attributes we permit.
    # The translators are considered trusted, but nevertheless this
    # limits problems if their accounts are subverted.
    # Translation text is okay iff the results of "sanitizing" it are
    # same as when we simply "regularize" the text without sanitizing it.
    sanitized = sanitize_html(text)
    regularized = regularize_html(text)
    sanitized == regularized
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # Recursively check locale text, e.g., ensure it has acceptable HTML
  # We pass "from" so that if there's a problem we can report exactly
  # where the problem comes from (making it easier to fix).
  # To recurse we really want kind_of?, not is_a?, so disable rubocop rule
  # rubocop:disable Style/ClassCheck, Metrics/MethodLength
  def check_text(translation, from)
    if translation.kind_of?(Array)
      translation.each_with_index { |i, part| check_text(part, from + [i]) }
    elsif translation.kind_of?(Hash)
      translation.each { |key, part| check_text(part, from + [key]) }
    elsif translation.kind_of?(String) # includes safe_html
      assert acceptable_html_string(translation.to_s),
             "Locale text failure in #{from.join('.')} : #{translation}"
    else
      assert simple_type(translation),
             "Locale text type failure in #{from.join('.')} : #{translation}"
    end
  end
  # rubocop:enable Style/ClassCheck, Metrics/MethodLength

  test 'All text values (all locales) include only acceptable HTML' do
    I18n.available_locales.each do |loc|
      check_text(I18n.t('.', locale: loc), [loc])
    end
  end
end
