# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 5.0 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# Enable per-form CSRF tokens. Previous versions had false. CHANGED.
Rails.application.config.action_controller.per_form_csrf_tokens = true

# Enable origin-checking CSRF mitigation. Previous versions had false. CHANGED.
Rails.application.config.action_controller.forgery_protection_origin_check =
  true

# Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
# Previous versions had false.
ActiveSupport.to_time_preserves_timezone = false

# Require `belongs_to` associations by default. Previous versions had false.
Rails.application.config.active_record.belongs_to_required_by_default = false

# To improve security, Rails 5.2.* embeds the expiry information
# also in encrypted or signed cookies value.
# This new embed information make those cookies incompatible with
# versions of Rails older than 5.2.
# That would log off users who are trying to save values, so disable for now.
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption =
  false
