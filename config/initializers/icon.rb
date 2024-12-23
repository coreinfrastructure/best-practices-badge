# frozen_string_literal: true

require Rails.root.join('app/models/icon.rb')

# Precalculate HTML for icons
Icon.initialize_class
