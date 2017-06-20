# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class TranslationsTest < ActiveSupport::TestCase
  test 'Translations.for_js should not have nil values' do
    assert_equal '', key_with_nil_value(Translations.instance.for_js)
  end

  test 'Translations.for_js has same keys as projects.misc.in_javascript' do
    I18n.available_locales.each do |l|
      assert_equal I18n.t('.projects.misc.in_javascript').keys.sort,
                   Translations.instance.for_js[l].keys.sort
    end
  end
end
