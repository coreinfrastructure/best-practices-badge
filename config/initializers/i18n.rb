# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Here we set the available locales.
#
# Rails requires that locales given (if any) must be an
# available locale by default (I18n.enforce_available_locales = true).
# We build on that by setting the available locales.
#
# The Rails default is as follows (this illustrates some options):
# [:en, :"en-BORK", :"de-CH", :fa, :"en-US", :"en-GB", :ja, :"en-NG", :es,
# :"en-UG", :"ca-CAT", :"en-PAK", :pt, :"de-AT", :nl, :"en-AU", :"en-ZA",
# :"nb-NO", :id, :"en-IND", :"es-MX", :"fi-FI", :ca, :ru, :fr, :"en-CA",
# :ko, :vi, :sv, :"da-DK", :he, :"en-SG", :tr, :"zh-CN", :pl, :it, :sk,
# :de, :"en-au-ocker", :"en-NZ", :"zh-TW", :"pt-BR", :nep, :uk, :ro, :da,
# :hu, :cs]
#
# The order here is English (the source language in this case), followed
# by the locales in English name order. Pagy initialization requires en first.
# This has the useful side-effect that Chinese is listed early, next to
# a Romance language, so it will be *immediately* obvious to users
# that this is the locale selection list.
# We maintain this order elsewhere, to reduce the risk that
# we'll accidentally omit a locale.  For example, see
# config/initializers/translation.rb

I18n.available_locales = %i[en zh-CN es fr de ja pt-BR ru sw].freeze

# Here are the locales we will *automatically* switch to.
# This *may* be the same as I18n.available_locales, but if a locale's
# translation isn't ready we will remove it here.
Rails.application.config.automatic_locales =
  (I18n.available_locales.dup - %i[es sw pt-BR]).freeze

# Automatic_locales must be a subset of I18n.available_locales - check it!
raise InvalidLocale unless
  (Rails.application.config.automatic_locales - I18n.available_locales).empty?

# The rest of the application uses those settings above automatically.
# For example, robots.txt counters crawling in these locales.
# To see how it does that, see:
# app/views/static_pages/robots.text.erb
#

# If we don't have text, fall back to English.  That obviously isn't
# ideal, but it's better to show *some* text to the user than leave it
# a mystery.
# ALSO: Gem i18n 1.1 changed fallbacks to exclude default locale. It says:
# > Please check your Rails app for 'config.i18n.fallbacks = true'.
# > If you're using I18n (>= 1.1.0) and Rails (< 5.2.2), this should be
# > 'config.i18n.fallbacks = [I18n.default_locale]'.
# > If not, fallbacks will be broken in your app by I18n 1.1.x.
Rails.application.config.i18n.fallbacks = [:en]
