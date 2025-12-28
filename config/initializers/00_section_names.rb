# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# **CANONICAL LISTS** of valid criteria level names and routing constants
#
# This file defines the authoritative list of criteria levels and sections
# used throughout the application. These constants are used by:
# - config/routes.rb - to build routing constraints
# - app/controllers - for validation and redirects
# - config/initializers/cors.rb - to build CORS resource patterns
#
# This file is named with "00_" prefix to ensure it loads early, but AFTER
# 00_criteria_hash.rb which loads the YAML and exports level keys.
#
# IMPORTANT: Level names are DERIVED from the YAML criteria files via
# constants exported from 00_criteria_hash.rb (YAML_METAL_LEVEL_KEYS and
# YAML_BASELINE_LEVEL_KEYS). This ensures YAML is loaded only once.
#
# All constants are in the Sections:: namespace to avoid global pollution
# and provide clear, canonical naming.
#
# When adding new criteria levels:
# 1. Add criteria to the appropriate YAML file
# 2. The level keys will auto-update via 00_criteria_hash.rb
# 3. Update Sections::REDIRECTS if adding obsolete synonyms
# 4. Update Sections::SPECIAL_FORMS if adding non-criteria sections

module Sections
  # Map of obsolete names to their canonical equivalents
  # This mapping is the authoritative source for canonical names
  # NOTE: The YAML files use obsolete numeric keys ('0', '1', '2')
  # but we route using canonical names ('passing', 'silver', 'gold')
  REDIRECTS = {
    '0' => 'passing',
    '1' => 'silver',
    '2' => 'gold',
    'bronze' => 'passing'
  }.freeze

  # Use level keys exported from 00_criteria_hash.rb (which loaded the YAML)
  # This avoids loading YAML twice - single source of truth

  # Metal badge levels - map numeric YAML keys to canonical names
  # The YAML uses '0', '1', '2' but we want canonical
  # E.g., ['passing', 'silver', 'gold']
  METAL_LEVEL_NAMES = YAML_METAL_LEVEL_KEYS.map { |k| REDIRECTS[k] || k }
                                           .freeze

  # Metal level numbers (obsolete keys still used in YAML)
  # E.g., ['0', '1', '2']
  METAL_LEVEL_NUMBERS = YAML_METAL_LEVEL_KEYS

  # Baseline badge levels (already use canonical names in YAML)
  # E.g., ['baseline-1', 'baseline-2', 'baseline-3']
  BASELINE_LEVEL_NAMES = YAML_BASELINE_LEVEL_KEYS

  # Synonyms for existing levels (obsolete names beyond numeric keys)
  SYNONYMS = %w[bronze].freeze # bronze = passing

  # Special forms (non-criteria sections - views/forms not tied to a criteria level)
  SPECIAL_FORMS = %w[permissions].freeze

  # All criteria levels (canonical names only - no obsolete numbers)
  # Built up from canonical level names derived from YAML
  ALL_CRITERIA_LEVEL_NAMES = (METAL_LEVEL_NAMES + BASELINE_LEVEL_NAMES).freeze

  # All canonical section names (criteria levels + special sections)
  # These are the preferred names that we redirect to - no obsolete names
  ALL_CANONICAL_NAMES = (ALL_CRITERIA_LEVEL_NAMES + SPECIAL_FORMS).freeze

  # Obsolete section names (deprecated, should redirect to canonical names)
  # Built up from obsolete numeric keys and synonym names
  OBSOLETE_NAMES = (METAL_LEVEL_NUMBERS + SYNONYMS).freeze

  # Valid section names (all names we accept - canonical + obsolete)
  # Used for validation where we accept obsolete names (then redirect to canonical)
  VALID_NAMES = (ALL_CANONICAL_NAMES + OBSOLETE_NAMES).freeze

  # Regex matching only primary/canonical section names
  # Used in controller validation and routes that reject obsolete names
  PRIMARY_SECTION_REGEX = Regexp.union(ALL_CANONICAL_NAMES)

  # Regex matching all valid section names (canonical + obsolete synonyms)
  # Used in routes.rb for :section parameter validation
  # (accepts obsolete for redirect)
  VALID_SECTION_REGEX = Regexp.union(VALID_NAMES)

  # Default section to use when none specified
  DEFAULT_SECTION = 'passing'
end
