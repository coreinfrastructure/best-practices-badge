# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Rails requires that locales given (if any) must be an
# available locale by default (I18n.enforce_available_locales = true).
# We build on that by setting the available locales.

# Here we set the available locales.
# The Rails default is as follows (this illustrates some options):
# [:en, :"en-BORK", :"de-CH", :fa, :"en-US", :"en-GB", :ja, :"en-NG", :es,
# :"en-UG", :"ca-CAT", :"en-PAK", :pt, :"de-AT", :nl, :"en-AU", :"en-ZA",
# :"nb-NO", :id, :"en-IND", :"es-MX", :"fi-FI", :ca, :ru, :fr, :"en-CA",
# :ko, :vi, :sv, :"da-DK", :he, :"en-SG", :tr, :"zh-CN", :pl, :it, :sk,
# :de, :"en-au-ocker", :"en-NZ", :"zh-TW", :"pt-BR", :nep, :uk, :ro, :da,
# :hu, :cs]

# NOTICE: If you add a locale, also modify robots.txt to prevent crawling of
# user accounts in that locale. See: app/views/static_pages/robots.text.erb

I18n.available_locales = %i[en zh-CN fr de ja ru].freeze

# Here are the locales we will *automatically* switch to.
# This *may* be the same as I18n.available_locales, but if a locale's
# translation isn't ready we should probably omit it here.
Rails.application.config.automatic_locales = I18n.available_locales.dup.freeze

# Automatic_locales must be a subset of I18n.available_locales - check it!
raise InvalidLocale unless
  (Rails.application.config.automatic_locales - I18n.available_locales).empty?

# If we don't have text, fall back to English.  That obviously isn't
# ideal, but it's better to show *some* text to the user than leave it
# a mystery.
Rails.application.config.i18n.fallbacks = [:en]
