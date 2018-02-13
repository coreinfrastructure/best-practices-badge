# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ApplicationHelper
  # Returns the tag for a given icon.
  # In font-awesome 5, the category "fab" is used for brands,
  # while "fas" is used for general (solid) icons.
  # Currently we use an icon file; in the future we
  # might use a reference to an SVG or SVG sprite.
  def my_icon_tag(icon, category = 'fa')
    # Unfortunately, rubocop doesn't realize that constants are safe,
    # so we have to disable the OutputSafety check here.
    # rubocop: disable Rails/OutputSafety
    ('<i class="'.html_safe + category + ' '.html_safe + icon +
      '" aria-hidden="true"></i>&nbsp;'.html_safe)
    # rubocop: enable Rails/OutputSafety
  end
end
