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

  # Return first unacceptable HTML in x (recursively), else (nil|false)
  # To recurse we really want kind_of?, not is_a?, so disable rubocop rule
  # rubocop:disable Style/ClassCheck, Metrics/MethodLength
  def find_unacceptable_html(translation)
    if translation.kind_of?(Array) || translation.kind_of?(Hash)
      translation.find { |part| find_unacceptable_html(part) }
    elsif translation.kind_of?(String) # includes safe_html
      return nil unless translation.include?('<') # Can't be a problem, no '<'
      # Translation text is okay if the results of "sanitizing" it are
      # same as when we simply "regularize" the text without sanitizing it.
      sanitized = sanitize_html(translation)
      regularized = regularize_html(translation)
      if sanitized != regularized
        p "Unacceptable HTML.\nSan=<#{sanitized}>\nReg=<#{regularized}>"
      end
      sanitized != regularized
    else
      !simple_type(translation) # else must be simple: symbol, number, etc.
    end
  end
  # rubocop:enable Style/ClassCheck, Metrics/MethodLength

  test 'All text values (all locales) include only acceptable HTML' do
    I18n.available_locales.each do |loc|
      assert_not find_unacceptable_html(I18n.t('.', locale: loc))
    end
  end
end
