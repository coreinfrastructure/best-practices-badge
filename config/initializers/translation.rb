# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Support translation.io.  See:
# https://translation.io/david-a-wheeler/cii-best-practices-badge/

if Rails.env.development? || Rails.env.test?
  require 'translation'
  TranslationIO.configure do |config|
    config.api_key        = 'b6086a4661ba47d79ec771236e298211'
    config.source_locale  = 'en'
    config.target_locales = %i[zh-CN es fr de ja pt-BR ru sw]

    # Uncomment this if you don't want to use gettext
    config.disable_gettext = true

    # Uncomment this if you already use gettext or fast_gettext
    # config.locales_path = File.join('path', 'to', 'gettext_locale')

    # Find other useful usage information here:
    # https://github.com/aurels/translation-gem/blob/master/README.md
    config.ignored_key_prefixes = [
      'rails.',
      'number.human.',
      'date.',
      'time.',
      'errors.',
      'datetime.',
      'admin.',
      'errors.messages.',
      'activerecord.errors.messages.',
      'will_paginate.',
      'helpers.page_entries_info.',
      'views.pagination.',
      'enumerize.visibility.'
    ]
  end
end
