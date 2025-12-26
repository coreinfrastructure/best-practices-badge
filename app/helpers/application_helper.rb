# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ApplicationHelper
  include Pagy::Frontend

  # Frozen string constant for unknown project names (memory optimization)
  NAME_UNKNOWN = '(Name Unknown)'

  # Pre-computed section dropdown data for project show navigation
  # Frozen hash keyed by locale to avoid rebuilding on every render
  # rubocop:disable Style/MutableConstant, Style/MethodCalledOnDoEndBlock
  PROJECT_NAV_SECTIONS =
    {}.tap do |hash|
      I18n.available_locales.each do |locale|
        hash[locale] = [
          {
            name: I18n.t('projects.form_early.level.0', locale: locale),
            level: 'passing'
          },
          {
            name: I18n.t('projects.form_early.level.1', locale: locale),
            level: 'silver'
          },
          {
            name: I18n.t('projects.form_early.level.2', locale: locale),
            level: 'gold'
          },
          {
            name: I18n.t('projects.edit.permissions_panel_title',
                         locale: locale, default: 'Permissions'),
            level: 'permissions'
          }
        ].freeze
      end
    end.freeze
  # rubocop:enable Style/MutableConstant, Style/MethodCalledOnDoEndBlock
end
