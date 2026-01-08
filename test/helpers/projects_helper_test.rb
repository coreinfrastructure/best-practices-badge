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
    # We now permit safe HTML tags like <i> for formatting, but dangerous
    # attributes are stripped by the HardenedScrubber.
    assert_equal "<p><i>hi</i></p>\n", markdown('<i>hi</i>')
  end

  test 'markdown - bare URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" ' \
      'rel="nofollow ugc noopener noreferrer">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('http://www.dwheeler.com')
    )
  end

  test 'markdown - angles around URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" ' \
      'rel="nofollow ugc noopener noreferrer">' \
      "http://www.dwheeler.com</a></p>\n",
      markdown('<http://www.dwheeler.com>')
    )
  end

  test 'markdown - hyperlinks are generated with nofollow' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com" ' \
      'rel="nofollow ugc noopener noreferrer">' \
      "Hello</a></p>\n",
      markdown('[Hello](http://www.dwheeler.com)')
    )
  end

  test 'markdown - raw HTML a stripped out (enforcing nofollow)' do
    # We now allow <a href="..."> BUT the HardenedScrubber forcibly injects
    # rel="nofollow ugc noopener noreferrer" on ALL anchor tags, so users
    # cannot bypass the nofollow requirement. This is actually safer than
    # the old approach.
    # Negative test (security) - verifies nofollow is forced
    assert_equal(
      '<p><a href="https://www.dwheeler.com" ' \
      'rel="nofollow ugc noopener noreferrer">Junk</a></p>' \
      "\n",
      markdown('<a href="https://www.dwheeler.com">Junk</a>')
    )
  end

  test 'markdown - no script HTML' do
    # Allowing <script> would be a big security vulnerability.
    # Commonmarker's tagfilter escapes it to &lt;script&gt; which is safe
    # (not executable). The escaped text is visible but harmless.
    # Negative test (security)
    assert_equal(
      "&lt;script src=\"hi\"&gt;&lt;/script&gt;Hello\n",
      markdown('<script src="hi"></script>Hello')
    )
  end

  test 'markdown - Embedded onclick rejected' do
    # We now allow safe tags like "i", but the HardenedScrubber strips
    # dangerous attributes like onclick. The tag remains but is safe.
    # Negative test (security)
    assert_equal "<p><i>hi</i></p>\n", markdown('<i onclick="alert();">hi</i>')
  end

  test 'markdown - _target not included' do
    # We now permit <a href=...>, but the HardenedScrubber strips the
    # dangerous target="..." attribute AND forcibly injects
    # rel="nofollow ugc noopener noreferrer" for protection.
    # This is a negative test to ensure that target="..." is stripped. See:
    # "Target="_blank" - the most underestimated vulnerability ever"
    # by Alexander "Alex" Yumashev, May 4 2016
    # https://www.jitbit.com/alexblog/
    # 256-targetblank---the-most-underestimated-vulnerability-ever/
    assert_equal(
      '<p><a href="https://www.dwheeler.com" ' \
      'rel="nofollow ugc noopener noreferrer">Hello</a></p>' \
      "\n",
      markdown('<a href="https://www.dwheeler.com" target="_blank">Hello</a>')
    )
  end

  test 'markdown - javascript: URL scheme rejected' do
    # javascript: URLs are a major XSS attack vector. We only allow
    # http, https, and mailto schemes (ALLOWED_PROTOCOLS).
    # The HardenedScrubber strips the dangerous href but leaves the
    # harmless <a> tag (an anchor without href is just text styling).
    # Negative test (security)
    result = markdown('[Click me](javascript:alert("XSS"))')
    # At the least this should be true:
    assert_not result.include?('javascript:'),
               'javascript: URL scheme should not appear in output'
    # Other secure results are *possible*, but we'll check for the
    # specific known-safe results.
    assert_not result.include?('href'),
               'href attribute should be stripped from javascript: URL'
    assert_equal(
      '<p><a rel="nofollow ugc noopener noreferrer">Click me</a></p>' \
      "\n",
      result
    )
  end

  test 'markdown - javascript: URL scheme in raw HTML rejected' do
    # Test that javascript: URLs in raw HTML anchor tags are also blocked.
    # The HardenedScrubber strips the dangerous href attribute.
    # Negative test (security)
    result = markdown('<a href="javascript:alert(\'XSS\')">Click</a>')
    assert_not result.include?('javascript:'),
               'javascript: URL should not appear in output'
    # More specific expected results; other secure results are possible
    assert_not result.include?('href'),
               'href attribute should be stripped'
    result = markdown('<a href="javascript:alert(\'XSS\')">Click</a>')
    assert_equal(
      '<p><a rel="nofollow ugc noopener noreferrer">Click</a></p>' \
      "\n",
      result
    )
  end

  test 'markdown - invalid URI has href stripped' do
    # URIs that cause URI::InvalidURIError should have their href removed.
    # This tests line 96 in markdown_processor.rb (rescue clause).
    # The HardenedScrubber catches the exception and strips the href.
    # Negative test (security)
    # Using a malformed URI with invalid characters
    result = markdown('<a href="ht!tp://bad[url]">Link</a>')
    # The link text should remain in a harmless <a> tag without href
    assert_not result.include?('href'),
               'Invalid URI should have href attribute stripped'
    assert_equal(
      '<p><a rel="nofollow ugc noopener noreferrer">Link</a></p>' \
      "\n",
      result
    )
  end

  test 'markdown - imbalanced HTML tags are automatically balanced' do
    # The HTML parser/sanitizer automatically balances tags to prevent
    # layout breakage or context escaping. This is important for security
    # to *not* allow unbalanced tags. For us, unclosed tags get closed.
    assert_equal "<p><i>hello</i></p>\n", markdown('<i>hello')
    assert_equal "<p><strong>world</strong></p>\n", markdown('<strong>world')
    # Orphaned closing tags get removed
    assert_equal "<p>hello</p>\n", markdown('hello</i>')
    # Multiple unclosed tags are properly nested and closed
    result = markdown('<i>hello <strong>world')
    # Verify tags are balanced (same number of opening and closing)
    assert_equal result.scan('<i>').length, result.scan('</i>').length
    assert_equal result.scan('<strong>').length, result.scan('</strong>').length
    # Specific result - other results could also be okay
    assert_equal "<p><i>hello <strong>world</strong></i></p>\n", result
  end

  test 'markdown - trivial text' do
    # Test to make sure our optimization for simple text doesn't cause
    # obvious weird problems.
    assert_equal "<p>Simple text.</p>\n", markdown('Simple text.')
  end

  test 'markdown - nil' do
    assert_equal '', markdown(nil)
  end

  test 'MarkdownProcessor HARDENED_TAGS and HARDENED_ATTRS values' do
    # This test documents the exact allowed tags and attributes in our
    # markdown processor. If this test fails after a Rails upgrade, it means
    # Rails::Html::SafeListSanitizer defaults have changed, and we need to
    # manually review whether the new values are acceptable for our
    # security requirements.
    #
    # HARDENED_TAGS = Rails safe list MINUS img, video, audio, details, summary
    # We remove media tags to discourage spam/SEO abuse, and details/summary
    # because they can hide important information.
    expected_tags = %w[
      a abbr acronym address b big blockquote br cite code dd del dfn div dl
      dt em h1 h2 h3 h4 h5 h6 hr i ins kbd li mark ol p pre samp small span
      strong sub sup time tt ul var
    ]
    assert_equal expected_tags, MarkdownProcessor::HARDENED_TAGS.sort,
                 'HARDENED_TAGS changed - review security implications'

    # HARDENED_ATTRS = Rails safe list MINUS class, id, target PLUS rel
    # We remove class/id (display manipulation), target (security vuln).
    # We add rel (needed for nofollow injection).
    expected_attrs = %w[
      abbr alt cite datetime height href lang name rel src title width xml:lang
    ]
    assert_equal expected_attrs, MarkdownProcessor::HARDENED_ATTRS.sort,
                 'HARDENED_ATTRS changed - review security implications'
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

  # We've commented out this mapping, so there's nothing to test.
  # test 'BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP is frozen and contains reverse mappings' do
  #   # Verify the constant is frozen for thread safety
  #   assert ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.frozen?
  #   # Verify it contains at least some baseline field mappings
  #   assert ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.any?
  #   # Verify sample reverse mappings are correct
  #   if ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP.key?('OSPS-AC-01.01_status')
  #     assert_equal 'osps_ac_01_01_status',
  #                  ProjectsHelper::BASELINE_DISPLAY_TO_INTERNAL_NAME_MAP['OSPS-AC-01.01_status']
  #   end
  # end

  test 'baseline_id_to_display uses precomputed map' do
    # Verify it returns correct values for baseline IDs
    assert_equal 'OSPS-AC-03.01', baseline_id_to_display('osps_ac_03_01')
    assert_equal 'OSPS-BR-01.02_status',
                 baseline_id_to_display('osps_br_01_02_status')
    # Verify it returns original for non-baseline IDs
    assert_equal 'name', baseline_id_to_display('name')
  end

  test 'compute_baseline_display_name handles 4-part baseline IDs' do
    # Test line 237: parts.size == 4 case
    result = ProjectsHelper.send(:compute_baseline_display_name,
                                 'osps_ac_03_01')
    assert_equal 'OSPS-AC-03.01', result
  end

  test 'compute_baseline_display_name returns original for malformed IDs' do
    # Test line 242: else case for unrecognized format
    # osps_ prefix but wrong number of parts
    result = ProjectsHelper.send(:compute_baseline_display_name,
                                 'osps_invalid')
    assert_equal 'osps_invalid', result
  end

  test 'compute_baseline_internal_name returns original for non-baseline' do
    # Test line 256: return early if not OSPS- format
    result = ProjectsHelper.send(:compute_baseline_internal_name,
                                 'version_semver')
    assert_equal 'version_semver', result
  end

  test 'compute_baseline_internal_name converts baseline display to internal' do
    # Test line 260: convert OSPS- format to internal
    result = ProjectsHelper.send(:compute_baseline_internal_name,
                                 'OSPS-AC-03.01')
    assert_equal 'osps_ac_03_01', result
  end

  # If we uncomment baseline_id_to_internal, here are tests for it.
  # test 'baseline_id_to_internal uses precomputed map' do
  #   # Verify it returns correct values for baseline display names
  #   assert_equal 'osps_ac_03_01', baseline_id_to_internal('OSPS-AC-03.01')
  #   assert_equal 'osps_br_01_02_status',
  #                baseline_id_to_internal('OSPS-BR-01.02_status')
  #   # Verify it returns original for non-baseline IDs
  #   assert_equal 'name', baseline_id_to_internal('name')
  # end

  # test 'baseline_id_to_internal converts display to internal form' do
  #   assert_equal 'osps_ac_03_01', baseline_id_to_internal('OSPS-AC-03.01')
  #   assert_equal 'osps_br_01_02', baseline_id_to_internal('OSPS-BR-01.02')
  #   assert_equal 'osps_qa_05_02', baseline_id_to_internal('osps-qa-05.02')
  # end

  # test 'baseline_id_to_internal returns original for non-baseline IDs' do
  #   assert_equal 'version_semver', baseline_id_to_internal('version_semver')
  #   assert_equal 'crypto_password_storage',
  #                baseline_id_to_internal('crypto_password_storage')
  # end

  test 'status_to_string converts integer 0 to ?' do
    assert_equal '?', status_to_string(0)
  end

  test 'status_to_string converts integer 1 to Unmet' do
    assert_equal 'Unmet', status_to_string(1)
  end

  test 'status_to_string converts integer 2 to N/A' do
    assert_equal 'N/A', status_to_string(2)
  end

  test 'status_to_string converts integer 3 to Met' do
    assert_equal 'Met', status_to_string(3)
  end

  test 'status_to_string returns nil for nil input' do
    assert_nil status_to_string(nil)
  end
end
# rubocop:enable Metrics/ClassLength
