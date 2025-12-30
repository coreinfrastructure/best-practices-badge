# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# CriterionStatus provides constants and conversion methods for
# criterion status values. Status values are stored as smallint (0-3)
# in the database but presented as strings ('?', 'Unmet', 'N/A', 'Met')
# in the external API for backward compatibility and easier understanding.
#
# This module centralizes the integer-to-string mapping for all status fields,
# enabling memory and storage optimization while maintaining API compatibility.
#
# Integer values are chosen for natural ordering:
# - 0: Unknown (?)
# - 1: Unmet
# - 2: N/A (Not Applicable)
# - 3: Met - selected as "3" so a 1-bit error can't convert Unknown to Met
#
# Usage:
#   CriterionStatus::MET              # => 3
#   CriterionStatus::STATUS_VALUES[3] # => 'Met'
#   CriterionStatus::STATUS_BY_NAME['Met'] # => 3
module CriterionStatus
  # Array mapping integer values to their string representations
  # Index = integer value, Value = string name
  # This is the single source of truth - all other constants are derived from it
  STATUS_VALUES = [
    '?',     # 0: UNKNOWN
    'Unmet', # 1: UNMET
    'N/A',   # 2: NA
    'Met'    # 3: MET
  ].freeze

  # Hash mapping string names to their integer values
  # Derived from STATUS_VALUES - used for converting incoming string parameters
  # rubocop:disable Style/MethodCalledOnDoEndBlock
  STATUS_BY_NAME = STATUS_VALUES.each_with_index.to_h do |name, index|
    [name, index]
  end.freeze
  # rubocop:enable Style/MethodCalledOnDoEndBlock

  # Integer constants for status values (derived from STATUS_BY_NAME)
  # These are the canonical values stored in the database
  UNKNOWN = STATUS_BY_NAME['?'] # 0
  UNMET = STATUS_BY_NAME['Unmet'] # 1
  NA = STATUS_BY_NAME['N/A'] # 2
  MET = STATUS_BY_NAME['Met'] # 3
end
