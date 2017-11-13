# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class ProjectsHelperTest < ActionView::TestCase
  include ProjectsHelper

  test 'markdown - simple' do
    assert_equal "<p>hi</p>\n", markdown('hi')
  end

  test 'markdown - emphasis' do
    assert_equal "<p><em>hi</em></p>\n", markdown('*hi*')
  end

  test 'markdown - bare URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('http://www.dwheeler.com')
    )
  end

  test 'markdown - angles around URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('<http://www.dwheeler.com>')
    )
  end

  test 'markdown - no script HTML' do
    # Allowing <script> would be a big security vulnerability.
    # This is a negative test to make sure we're filtering it out.
    assert_equal(
      "<p>Hello</p>\n",
      markdown('<script src="hi"></script>Hello')
    )
  end

  test 'markdown - _target not included' do
    # In the future we might permit <a href=...>, but we must NOT allow
    # target="..." in it because that's a security vulnerability.
    # This is a negative test to ensure that target="..." isn't allowed. See:
    # "Target="_blank" - the most underestimated vulnerability ever"
    # by Alexander "Alex" Yumashev, May 4 2016
    # https://www.jitbit.com/alexblog/
    # 256-targetblank---the-most-underestimated-vulnerability-ever/
    assert_equal(
      "<p>Hello</p>\n",
      markdown('<a href="https://www.dwheeler.com" target="_blank">Hello</a>')
    )
  end
end
