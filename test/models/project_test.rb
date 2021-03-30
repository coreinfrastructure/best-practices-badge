# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ProjectTest < ActiveSupport::TestCase
  using StringRefinements
  setup do
    @user = users(:test_user)
    @project = @user.projects.build(
      homepage_url: 'https://www.example.org',
      repo_url: 'https://www.example.org/code'
    )
    @unjustified_project = projects(:perfect_unjustified)
    @project_passing = projects(:perfect_passing)
    @project_silver = projects(:perfect_silver)
    @project_gold = projects(:perfect)
  end

  test 'should be valid' do
    assert @project.valid?
  end

  test 'user id should be present' do
    @project.user_id = nil
    assert_not @project.valid?
  end

  test '#contains_url?' do
    assert Project.new.contains_url? 'https://www.example.org'
    assert Project.new.contains_url? 'http://www.example.org'
    assert Project.new.contains_url? 'See also http://x.org.'
    assert Project.new.contains_url? 'See also <http://x.org>.'
    assert_not Project.new.contains_url? 'mailto://mail@example.org'
    assert_not Project.new.contains_url? 'abc'
    assert_not(
      Project.new.contains_url?('See also http://x for more information.')
    )
    assert_not Project.new.contains_url? 'www.google.com'
  end

  # rubocop:disable Metrics/BlockLength
  test 'Rigorous project and repo URL checker' do
    regex = UrlValidator::URL_REGEX
    my_url = 'https://github.com/coreinfrastructure/best-practices-badge'
    assert my_url =~ regex

    # Here we just the regex directly, to make sure it's okay.
    assert 'https://kernel.org' =~ regex
    assert_not 'https://' =~ regex
    assert_not 'www.google.com' =~ regex
    assert_not 'See also http://x.org for more information.' =~ regex
    assert_not 'See also <http://x.org>.' =~ regex

    # Here we use the full validator.  We stub out the info necessary
    # to create a validator instance to test (we won't really use them).
    validator = UrlValidator.new(attributes: %i[repo_url project_url])
    assert validator.url_acceptable?(my_url)
    assert validator.url_acceptable?('https://kernel.org')
    assert validator.url_acceptable?('') # Empty allowed.
    assert_not validator.url_acceptable?('https://')
    assert_not validator.url_acceptable?('www.google.com')
    assert_not validator.url_acceptable?('See also http://x.org for more.')
    assert_not validator.url_acceptable?('See also <http://x.org>.')
    assert validator.url_acceptable?('http://google.com')
    # We don't allow '?'
    assert_not validator.url_acceptable?('http://google.com?hello')
    # We do allow fragments, e.g., #
    assert_not validator.url_acceptable?('http://google.com#hello')

    # Accept U+0020 (space) and U+00E9 c3 a9 "LATIN SMALL LETTER E WITH ACUTE"
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%20%c3%a9')
    # Accept U+8C0A Unicode Han Character 'friendship; appropriate, suitable'
    # encoded in UTF-8 as 0xE8 0xB0 0x8A (e8b08a); see
    # http://www.fileformat.info/info/unicode/char/8c0a/index.htm
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    '%E8%B0%8A')
    # Accept U+1000 Unicode Character 'MYANMAR LETTER KA'
    # encoded in UTF-8 as 0xE1 0x80 0x80
    # http://www.fileformat.info/info/unicode/char/1000/index.htm
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    '%e1%80%80')
    # Don't accept "c0 80", an overlong (2-byte) encoding of U+0000 (NUL).
    # Note that "modified UTF-8" does accept this.
    assert_not validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%20%c0%80')
    # Don't accept non-UTF-8, even if the individual bytes are acceptable.
    assert_not validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%eex')
    assert_not validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%ee')
    assert_not validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%ff%ff')
  end
  # rubocop:enable Metrics/BlockLength

  test 'UTF-8 validator should refute non-UTF-8 encoding' do
    validator = TextValidator.new(attributes: %i[name description])
    # Don't accept non-UTF-8, even if the individual bytes are acceptable.
    assert_not validator.text_acceptable?("The best practices badge\255")
    assert_not validator.text_acceptable?("The best practices badge\xff\xff")
    assert_not validator.text_acceptable?("The best practices badge\xee")
    assert_not validator.text_acceptable?("The best practices badge\xe4")
    # Don't accept an invalid control character
    assert_not validator.text_acceptable?("The best practices badge\x0c")
    assert validator.text_acceptable?('The best practices badge.')
  end

  # rubocop:disable Metrics/BlockLength
  test 'test get_criterion_result returns correct values' do
    assert_equal(
      :criterion_url_required,
      @unjustified_project.get_criterion_result(Criteria['0'][:contribution])
    )
    assert_equal(
      :criterion_justification_required,
      @unjustified_project.get_criterion_result(Criteria['0'][:release_notes])
    )
    assert_equal(
      :criterion_justification_required,
      @unjustified_project.get_criterion_result(
        Criteria['0'][:test_invocation]
      )
    )
    assert_equal(
      :criterion_justification_required,
      @unjustified_project.get_criterion_result(
        Criteria['0'][:static_analysis]
      )
    )
    assert_equal(
      :criterion_barely,
      @unjustified_project.get_criterion_result(Criteria['0'][:test_most])
    )
    assert_equal(
      :criterion_failing,
      @unjustified_project.get_criterion_result(
        Criteria['1'][:crypto_certificate_verification]
      )
    )
    assert_equal(
      :criterion_unknown,
      @unjustified_project.get_criterion_result(
        Criteria['2'][:build_reproducible]
      )
    )
    assert_equal(
      :criterion_passing,
      @unjustified_project.get_criterion_result(
        Criteria['0'][:vulnerability_report_private]
      )
    )
  end
  # rubocop:enable Metrics/BlockLength

  # We had to add this test for coverage.
  test 'unit test string_refinements na?' do
    assert @unjustified_project.release_notes_status.na?
  end

  test 'check correct badge levels are returned' do
    assert_equal 'in_progress', @unjustified_project.badge_level
    assert_equal 'passing', @project_passing.badge_level
    assert_equal 'silver', @project_silver.badge_level
    assert_equal 'gold', @project_gold.badge_level
  end

  # This test works because we don't set the higher level prereqs in the
  # fixture files.  Make sure not to change this.
  test 'check update_prereqs works correctly for level upgrades' do
    assert_equal 'Unmet', @unjustified_project.achieve_passing_status
    assert_equal 'Unmet', @project_passing.achieve_passing_status
    assert_equal 'Unmet', @project_passing.achieve_silver_status
    assert_equal 'Met', @project_silver.achieve_passing_status
    assert_equal 'Unmet', @project_silver.achieve_silver_status
    assert @project_silver.achieved_silver_at.blank?
    assert @project_silver.first_achieved_silver_at.blank?
    Project.update_all_badge_percentages(Criteria.keys)
    assert_equal(
      'Unmet', Project.find(@unjustified_project.id).achieve_passing_status
    )
    assert_equal(
      'Met', Project.find(@project_passing.id).achieve_passing_status
    )
    assert_equal(
      'Unmet', Project.find(@project_passing.id).achieve_silver_status
    )
    updated_project = Project.find(@project_silver.id)
    assert_equal 'Met', updated_project.achieve_passing_status
    assert_equal 'Met', updated_project.achieve_silver_status
  end

  test 'update_prereqs works correctly for level downgrades' do
    assert_equal 'Met', @project_silver.achieve_passing_status
    @project_silver.update!(description_good_status: 'Unmet')
    assert_equal(
      'Unmet', Project.find(@project_silver.id).achieve_passing_status
    )
  end

  # The number of named badge levels must be equal to the number of
  # criteria levels + 1, because projects can be "in_progress"
  test 'test all possible badge "levels/statuses" are named' do
    assert_equal Criteria.count + 1, Project::BADGE_LEVELS.size
  end

  test 'Project counts from fixtures are as expected' do
    assert_equal 4, Project.in_progress.count
    assert_equal 3, Project.passing.count
  end

  test 'test get_satisfaction_data' do
    basics = @unjustified_project.get_satisfaction_data('0', 'basics')
    assert_equal '10/13', basics[:text]
    assert_equal 'hsl(92, 100%, 50%)', basics[:color]
    reporting = @unjustified_project.get_satisfaction_data('0', 'reporting')
    assert_equal '5/8', reporting[:text]
    assert_equal 'hsl(75, 100%, 50%)', reporting[:color]
    quality = @unjustified_project.get_satisfaction_data('0', 'quality')
    assert_equal '12/13', quality[:text]
    assert_equal 'hsl(111, 100%, 50%)', quality[:color]
  end

  test 'Justification goodness' do
    # Use "send" to do unit tests of a private method.
    assert @unjustified_project.send(
      :justification_good?,
      'This is long enough.'
    )
    assert_not @unjustified_project.send(
      :justification_good?,
      '// This is a comment.'
    )
    assert_not @unjustified_project.send(:justification_good?, 'bah.')
    assert_not @unjustified_project.send(:justification_good?, '')
    assert_not @unjustified_project.send(:justification_good?, nil)
  end

  # rubocop:disable Metrics/BlockLength
  test 'test :skip_callbacks works as expected' do
    project_one = projects(:one)
    Project.skip_callbacks = true
    # With skip_callbacks = true there should be
    # no change to percentages on save.
    assert_no_difference [
      'Project.find(projects(:one).id).badge_percentage_0',
      'Project.find(projects(:one).id).badge_percentage_1'
    ] do
      project_one.update!(
        crypto_weaknesses_status: 'Met',
        crypto_weaknesses_justification: 'It is good'
      )
    end
    Project.skip_callbacks = false
    old_percentage0 = Project.find(projects(:one).id).badge_percentage_0
    old_percentage1 = Project.find(projects(:one).id).badge_percentage_1
    project_one.update!(
      warnings_strict_status: 'Met',
      warnings_strict_justification: 'It is good'
    )
    # Check the badge percentage changed
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage_0,
      old_percentage0
    )
    assert_not_equal(
      Project.find(projects(:one).id).badge_percentage_1,
      old_percentage1
    )
  end
  # rubocop:enable Metrics/BlockLength

  test 'compute_tiered_percentage works' do
    # Simple unit test of 'compute_tiered_percentage'
    p = Project.new
    # Very different numbers so correct answer unlikely to happen by chance
    p.badge_percentage_0 = 31
    p.badge_percentage_1 = 17
    p.badge_percentage_2 = 4
    assert_equal 31, p.compute_tiered_percentage
    p.badge_percentage_0 = 100
    assert_equal 117, p.compute_tiered_percentage
    p.badge_percentage_1 = 100
    assert_equal 204, p.compute_tiered_percentage
    p.badge_percentage_2 = 100
    assert_equal 300, p.compute_tiered_percentage
    p.badge_percentage_0 = 85
    assert_equal 85, p.compute_tiered_percentage
  end
end
# rubocop:enable Metrics/ClassLength
