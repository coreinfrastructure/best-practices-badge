# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ProjectsHelperTest < ActionView::TestCase
  include ProjectsHelper

  test 'markdown - simple' do
    assert_equal "<p>hi</p>\n", markdown('hi')
  end

  test 'markdown - emphasis' do
    assert_equal "<p><em>hi</em></p>\n", markdown('*hi*')
  end

  test 'markdown - Embedded HTML i filtered out' do
    # In the future we might permit this, but if we do, we need to make
    # sure only safe attributes are allowed.  Since users can just use
    # markdown, there's no rush to support embedded HTML.
    assert_equal "<p>hi</p>\n", markdown('<i>hi</i>')
  end

  test 'markdown - bare URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" rel="nofollow ugc">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('http://www.dwheeler.com')
    )
  end

  test 'markdown - angles around URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" rel="nofollow ugc">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('<http://www.dwheeler.com>')
    )
  end

  test 'markdown - hyperlinks are generated with nofollow' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" rel="nofollow ugc">' \
      "Hello</a></p>\n",
      markdown('[Hello](http://www.dwheeler.com)')
    )
  end

  test 'markdown - raw HTML a stripped out (enforcing nofollow)' do
    # Allowing <a href="..."> would let people insert a link without nofollow,
    # so we don't allow the use of <a ...>.  People can insert a hyperlink,
    # but they have to use the markdown format [test](URL), and that format
    # gives us an opportunity to forcibly insert rel="nofollow ugc".
    # Negative test (security)
    assert_equal(
      "<p>Junk</p>\n",
      markdown('<a href="https://www.dwheeler.com">Junk</a>')
    )
  end

  test 'markdown - no script HTML' do
    # Allowing <script> would be a big security vulnerability.
    # This is a negative test to make sure we're filtering it out.
    # Negative test (security)
    assert_equal(
      "<p>Hello</p>\n",
      markdown('<script src="hi"></script>Hello')
    )
  end

  test 'markdown - Embedded onclick rejected' do
    # In the future we might allow "i", but we must continue to
    # reject attributes unless we are sure they are safe.
    # Negative test (security)
    assert_equal "<p>hi</p>\n", markdown('<i onclick="alert();">hi</i>')
  end

  test 'markdown - _target not included' do
    # In the future we might permit <a href=...>, but we must NOT allow
    # target="..." in it because that's a security vulnerability.
    # This is a negative test to ensure that target="..." isn't allowed. See:
    # "Target="_blank" - the most underestimated vulnerability ever"
    # by Alexander "Alex" Yumashev, May 4 2016
    # https://www.jitbit.com/alexblog/
    # 256-targetblank---the-most-underestimated-vulnerability-ever/
    assert_equal(
      "<p>Hello</p>\n",
      markdown('<a href="https://www.dwheeler.com" target="_blank">Hello</a>')
    )
  end

  test 'markdown - trivial text' do
    # Test to make sure our optimization for simple text doesn't cause
    # obvious weird problems.
    assert_equal "<p>Simple text.</p>\n", markdown('Simple text.')
  end

  test 'markdown - nil' do
    assert_equal '', markdown(nil)
  end

  test 'Ensure tiered_percent_as_string works' do
    I18n.with_locale(:de) do
      assert_equal 'In Arbeit, 74% Fortschritt für Passing',
                   tiered_percent_as_string(74)
    end
    I18n.with_locale(:en) do
      assert_nil tiered_percent_as_string(nil)
      assert_equal 'In Progress, 74% completed for passing',
                   tiered_percent_as_string(74)
      assert_equal 'Passing, 23% completed for silver',
                   tiered_percent_as_string(123)
      assert_equal 'Silver, 52% completed for gold',
                   tiered_percent_as_string(252)
      assert_equal 'Gold', tiered_percent_as_string(300)
    end
    # I18n.with_locale(:fr) do
    #    assert_equal 'WRONG', tiered_percent_as_string(74)
    # end
  end

  test 'Empty repo list works' do
    empty_result = fork_and_original([])
    assert_equal [[], []], empty_result
  end

  test 'baseline_id_to_display converts internal to display form' do
    assert_equal 'OSPS-AC-03.01', baseline_id_to_display('osps_ac_03_01')
    assert_equal 'OSPS-BR-01.02', baseline_id_to_display(:osps_br_01_02)
    assert_equal 'OSPS-QA-05.02', baseline_id_to_display('osps_qa_05_02')
  end

  test 'baseline_id_to_display returns original for non-baseline IDs' do
    assert_equal 'version_semver', baseline_id_to_display('version_semver')
    assert_equal 'crypto_password_storage',
                 baseline_id_to_display('crypto_password_storage')
  end

  test 'baseline_id_to_display converts field names with suffixes' do
    assert_equal 'OSPS-AC-03.01_status',
                 baseline_id_to_display('osps_ac_03_01_status')
    assert_equal 'OSPS-BR-01.02_justification',
                 baseline_id_to_display('osps_br_01_02_justification')
    assert_equal 'OSPS-QA-05.02_status',
                 baseline_id_to_display('osps_qa_05_02_status')
  end

  test 'baseline_id_to_display returns original for invalid suffixes' do
    # Should not convert field names with unrecognized suffixes
    assert_equal 'osps_ac_03_01_invalid',
                 baseline_id_to_display('osps_ac_03_01_invalid')
  end

  test 'BASELINE_FIELD_DISPLAY_NAME_MAP is frozen and contains mappings' do
    # Verify the constant is frozen for thread safety
    assert ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.frozen?
    # Verify it contains at least some baseline field mappings
    assert ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.any?
    # Verify sample mappings are correct
    if ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP.key?('osps_ac_01_01_status')
      assert_equal 'OSPS-AC-01.01_status',
                   ProjectsHelper::BASELINE_FIELD_DISPLAY_NAME_MAP['osps_ac_01_01_status']
    end
  end

  test 'BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP is frozen and contains reverse mappings' do
    # Verify the constant is frozen for thread safety
    assert ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.frozen?
    # Verify it contains at least some baseline field mappings
    assert ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.any?
    # Verify sample reverse mappings are correct
    if ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.key?('OSPS-AC-01.01_status')
      assert_equal 'osps_ac_01_01_status',
                   ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP['OSPS-AC-01.01_status']
    end
  end

  test 'baseline_id_to_display uses precomputed map' do
    # Verify it returns correct values for baseline IDs
    assert_equal 'OSPS-AC-03.01', baseline_id_to_display('osps_ac_03_01')
    assert_equal 'OSPS-BR-01.02_status',
                 baseline_id_to_display('osps_br_01_02_status')
    # Verify it returns original for non-baseline IDs
    assert_equal 'name', baseline_id_to_display('name')
  end

  test 'baseline_id_to_internal uses precomputed map' do
    # Verify it returns correct values for baseline display names
    assert_equal 'osps_ac_03_01', baseline_id_to_internal('OSPS-AC-03.01')
    assert_equal 'osps_br_01_02_status',
                 baseline_id_to_internal('OSPS-BR-01.02_status')
    # Verify it returns original for non-baseline IDs
    assert_equal 'name', baseline_id_to_internal('name')
  end

  test 'baseline_id_to_internal converts display to internal form' do
    assert_equal 'osps_ac_03_01', baseline_id_to_internal('OSPS-AC-03.01')
    assert_equal 'osps_br_01_02', baseline_id_to_internal('OSPS-BR-01.02')
    assert_equal 'osps_qa_05_02', baseline_id_to_internal('osps-qa-05.02')
  end

  test 'baseline_id_to_internal returns original for non-baseline IDs' do
    assert_equal 'version_semver', baseline_id_to_internal('version_semver')
    assert_equal 'crypto_password_storage',
                 baseline_id_to_internal('crypto_password_storage')
  end
end
# rubocop:enable Metrics/ClassLength
