# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

module Translations
  module_function

  # This class is a used to gather sets of translations which will commonly
  # be called in bulk.  For example, there are translations we would like
  # to export to JavaScript.  We can use a method here to do that quickly.

  def for_js
    js_translations =
      I18n.available_locales.map do |locale|
        locale_t =
          I18n.t('.projects.misc.in_javascript').keys.map do |k|
            [k, I18n.t(".projects.misc.in_javascript.#{k}", locale: locale)]
          end
        [locale, locale_t.to_h]
      end
    js_translations.to_h
  end
end
