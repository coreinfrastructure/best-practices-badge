# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Test the section name constants defined in config/initializers/00_section_names.rb
# rubocop:disable Metrics/ClassLength
class SectionNamesTest < ActiveSupport::TestCase
  test 'Sections::METAL_LEVEL_NAMES contains expected canonical names' do
    assert_equal %w[passing silver gold], Sections::METAL_LEVEL_NAMES
  end

  test 'Sections::METAL_LEVEL_NUMBERS contains expected obsolete numeric keys' do
    assert_equal %w[0 1 2], Sections::METAL_LEVEL_NUMBERS
  end

  test 'Sections::BASELINE_LEVEL_NAMES contains expected baseline levels' do
    assert_equal %w[baseline-1 baseline-2 baseline-3],
                 Sections::BASELINE_LEVEL_NAMES
  end

  test 'Sections::SYNONYMS contains expected obsolete synonyms' do
    assert_equal ['bronze'], Sections::SYNONYMS
  end

  test 'Sections::SPECIAL_FORMS contains expected special sections' do
    assert_equal ['permissions'], Sections::SPECIAL_FORMS
  end

  test 'Sections::REDIRECTS maps obsolete names to canonical names' do
    expected = {
      '0' => 'passing',
      '1' => 'silver',
      '2' => 'gold',
      'bronze' => 'passing'
    }
    assert_equal expected, Sections::REDIRECTS
  end

  test 'Sections::ALL_CRITERIA_LEVEL_NAMES contains all level names' do
    expected = %w[
      passing silver gold
      baseline-1 baseline-2 baseline-3
    ]
    assert_equal expected, Sections::ALL_CRITERIA_LEVEL_NAMES
  end

  test 'Sections::ALL_NAMES includes criteria levels and special forms' do
    expected = %w[
      passing silver gold
      baseline-1 baseline-2 baseline-3
      permissions
    ]
    assert_equal expected, Sections::ALL_NAMES
  end

  test 'Sections::OBSOLETE_NAMES includes numeric keys and synonyms' do
    expected = %w[0 1 2 bronze]
    assert_equal expected, Sections::OBSOLETE_NAMES
  end

  test 'Sections::VALID_NAMES equals ALL_NAMES (built from valid components)' do
    assert_equal Sections::ALL_NAMES, Sections::VALID_NAMES
  end

  test 'Sections::DEFAULT_SECTION is passing' do
    assert_equal 'passing', Sections::DEFAULT_SECTION
  end

  test 'Sections::PRIMARY_SECTION_REGEX matches primary section names' do
    # Should match canonical names
    assert 'passing'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert 'silver'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert 'gold'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert 'baseline-1'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert 'permissions'.match?(Sections::PRIMARY_SECTION_REGEX)

    # Should NOT match obsolete names
    assert_not '0'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert_not '1'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert_not '2'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert_not 'bronze'.match?(Sections::PRIMARY_SECTION_REGEX)

    # Should NOT match invalid names
    assert_not 'invalid'.match?(Sections::PRIMARY_SECTION_REGEX)
    assert_not 'foo'.match?(Sections::PRIMARY_SECTION_REGEX)
  end

  test 'Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX matches all section names' do
    # Should match canonical names
    assert 'passing'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert 'silver'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert 'baseline-1'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)

    # Should also match obsolete names
    assert '0'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert '1'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert '2'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert 'bronze'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)

    # Should NOT match invalid names
    assert_not 'invalid'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
    assert_not 'foo'.match?(Sections::PRIMARY_AND_SYNONYM_SECTION_REGEX)
  end

  test 'Top-level METAL_LEVEL_NAMES aliases Sections::METAL_LEVEL_NAMES' do
    assert_equal Sections::METAL_LEVEL_NAMES, METAL_LEVEL_NAMES
  end

  test 'Top-level BASELINE_LEVEL_NAMES aliases Sections::BASELINE_LEVEL_NAMES' do
    assert_equal Sections::BASELINE_LEVEL_NAMES, BASELINE_LEVEL_NAMES
  end

  test 'Top-level LEVEL_REDIRECTS aliases Sections::REDIRECTS' do
    assert_equal Sections::REDIRECTS, LEVEL_REDIRECTS
  end

  test 'Top-level ALL_CRITERIA_LEVEL_NAMES includes all level names' do
    # Top-level constant includes obsolete names for backward compatibility
    expected = %w[
      passing silver gold
      0 1 2
      baseline-1 baseline-2 baseline-3
      bronze
      permissions
    ]
    assert_equal expected, ALL_CRITERIA_LEVEL_NAMES
  end

  test 'Section names are frozen' do
    assert Sections::METAL_LEVEL_NAMES.frozen?
    assert Sections::BASELINE_LEVEL_NAMES.frozen?
    assert Sections::ALL_NAMES.frozen?
    assert Sections::OBSOLETE_NAMES.frozen?
    assert Sections::REDIRECTS.frozen?
    assert Sections::DEFAULT_SECTION.frozen?
  end

  test 'Section name arrays do not overlap incorrectly' do
    # METAL_LEVEL_NAMES and METAL_LEVEL_NUMBERS should not overlap
    assert_empty(Sections::METAL_LEVEL_NAMES & Sections::METAL_LEVEL_NUMBERS)

    # VALID_NAMES and OBSOLETE_NAMES should not overlap
    assert_empty(Sections::VALID_NAMES & Sections::OBSOLETE_NAMES)
  end
end
# rubocop:enable Metrics/ClassLength
