# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register 'image/svg+xml', :svg
Mime::Type.register 'text/plain; charset=UTF-8', :md

# We really should register markdown as:
# Mime::Type.register 'text/markdown; charset=UTF-8', :md
# but then it won't be inline, even when we do this:
# Rails.application.config.active_storage.content_types_allowed_inline += [
#    'text/markdown'
# ]
