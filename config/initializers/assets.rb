# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
# This adds criteria/criteria.yml to the asset pipeline.
Rails.application.config.assets.paths << Rails.root.join('criteria')
# This adds config/locales/* to the asset pipeline.
Rails.application.config.assets.paths << Rails.root.join('config', 'locales')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are
# already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile +=
  %w[project-form.js project-stats.js]
