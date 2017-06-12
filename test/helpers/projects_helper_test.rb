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
    assert_equal(
      "<p>Hello</p>\n",
      markdown('<script src="hi"></script>Hello')
    )
  end
end
