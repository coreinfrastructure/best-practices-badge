# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ApplicationHelper
  # Unfortunately, rubocop doesn't realize that concatenating
  # constants we define is safe.
  # rubocop: disable Rails/OutputSafety
  FA_HTML_SAFE = 'fa'.html_safe
  # rubocop: enable Rails/OutputSafety

  # Returns the tag for a given icon as a SafeBuffer.
  # In font-awesome 5, the category "fab" is used for brands,
  # while "fas" is used for general (solid) icons.
  # Currently we use an icon file; in the future we
  # might use a reference to an SVG or SVG sprite.
  def my_icon_tag(icon, category = FA_HTML_SAFE)
    # Unfortunately, rubocop doesn't realize that concatenating
    # constants we define is safe.
    # rubocop: disable Rails/OutputSafety
    res = ''.html_safe
    res.safe_concat('<i class="')
    res += category
    res.safe_concat(' ')
    res += icon
    res.safe_concat('" aria-hidden="true"></i>&nbsp;')
    # rubocop: enable Rails/OutputSafety
    res
  end
end
