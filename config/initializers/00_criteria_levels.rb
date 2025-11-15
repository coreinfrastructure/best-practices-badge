# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# **CANONICAL LISTS** of valid criteria level names for URLs and routing
#
# This file defines the authoritative list of criteria levels used throughout
# the application. These constants are used by:
# - config/routes.rb - to build routing constraints
# - config/initializers/cors.rb - to build CORS resource patterns
#
# This file is named with "00_" prefix to ensure it loads first among
# initializers (alphabetical loading order).
#
# When adding new criteria levels:
# 1. Add the level name to the appropriate array below
# 2. The routing constraints and CORS patterns will auto-update
# 3. Update controller normalization methods if needed
# 4. Update model helper methods if needed

# Metal badge levels (the original three tiers)
METAL_LEVEL_NAMES = %w[passing silver gold].freeze
METAL_LEVEL_NUMBERS = %w[0 1 2].freeze

# Baseline levels (planned future tiers)
BASELINE_LEVEL_NAMES = %w[baseline-1 baseline-2 baseline-3].freeze

# Synonyms for existing levels
LEVEL_SYNONYMS = %w[bronze].freeze # bronze = passing

# Special forms (non-standard views)
SPECIAL_FORMS = %w[permissions].freeze

# Combined list of all valid criteria level names
ALL_CRITERIA_LEVEL_NAMES = (
  METAL_LEVEL_NAMES + METAL_LEVEL_NUMBERS + BASELINE_LEVEL_NAMES +
  LEVEL_SYNONYMS + SPECIAL_FORMS
).freeze
