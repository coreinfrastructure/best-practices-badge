# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  # Check that basic internationalization (i18n) functionality is working
  test 'i18n sanity check' do
    assert_equal 'Hello world', I18n.t(:hello, locale: :en)
    assert_equal 'Bonjour le monde', I18n.t(:hello, locale: :fr)
    assert_equal '你好，世界', I18n.t(:hello, locale: :'zh-CN')
    assert_equal 'Здравствуй, мир', I18n.t(:hello, locale: :ru)
    assert_equal 'Last translation entry', I18n.t(:last_entry, locale: :en)
  end
end
