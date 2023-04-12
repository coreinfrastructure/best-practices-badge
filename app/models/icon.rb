# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This precomputes the text for each icon as safe_html.
# This is a singleton class.  It's complicated enough that
# it's useful to put in its own class.

class Icon
  class << self
    ICONS_TO_GENERATE = %i[
      fa-address-card
      fa-edit
      fa-github
      fa-list
      fa-plus
      fa-sign-in
      fa-sign-out
      fa-times-circle
      fa-user
      fa-user-plus
    ].freeze

    # Return the SafeBuffer text that represents icon "key".
    def [](key)
      # Use fetch, not @icon_data[key], so we discover missing keys
      @icon_data&.fetch(key)
    end

    # Useful for debugging
    def keys
      @icon_data.keys
    end

    def initialize_class
      @icon_data = {}
      ICONS_TO_GENERATE.each do |name|
        @icon_data[name] = my_icon_tag(name.to_s)
      end
      # Should we freeze it?
      nil
    end

    private

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
      res.freeze
    end
  end
end
