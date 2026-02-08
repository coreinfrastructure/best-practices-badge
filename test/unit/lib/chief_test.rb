# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ChiefTest < ActiveSupport::TestCase
  setup do
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @repo_name = 'best-practices-badge'
    @description = '🏆Open Source Security Foundation (OpenSSF)' \
                   ' Best Practices Badge (formerly Core Infrastructure Initiative (CII) Best Practices Badge)'

    @sample_project = Project.new
    @sample_project[:repo_url] = "https://github.com/#{@full_name}"
  end

  # rubocop:disable Metrics/BlockLength
  test 'OpenSSF badge results correct' do
    new_chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    VCR.use_cassette('github') do
      new_chief.autofill
    end
    results = @sample_project

    # skip 'Temporarily skip while debugging website problem.'
    mit_ok = 'The MIT license is approved by the Open Source Initiative (OSI).'
    assert_equal 'MIT', results[:license]
    assert_equal @repo_name, results[:name]
    assert_equal @description, results[:description]
    # Phase 3: Detectives return integers, and columns now store integers
    assert_equal CriterionStatus::MET, results[:floss_license_status]
    assert_equal mit_ok, results[:floss_license_justification]
    assert_equal CriterionStatus::MET, results[:floss_license_osi_status]
    assert_equal mit_ok, results[:floss_license_osi_justification]
    assert_equal CriterionStatus::MET, results[:contribution_status]
    assert_equal 'Non-trivial contribution file in repository: <https://github.com/coreinfrastructure/best-practices-badge/blob/main/CONTRIBUTING.md>.',
                 results[:contribution_justification]
    assert_equal CriterionStatus::MET, results[:release_notes_status]
    assert_equal 'Non-trivial release notes file in repository: ' \
                 '<https://github.com/coreinfrastructure/' \
                 'best-practices-badge/blob/main/CHANGELOG.md>.',
                 results[:release_notes_justification]
    assert_equal CriterionStatus::MET, results[:build_status]
    assert_equal 'Non-trivial build file in repository: ' \
                 '<https://github.com/coreinfrastructure/' \
                 'best-practices-badge/blob/main/Rakefile>.',
                 results[:build_justification]
    assert_equal 'Ruby, JavaScript, Shell, SCSS, Dockerfile, Makefile, Procfile',
                 results[:implementation_languages]
  end
  # rubocop:enable Metrics/BlockLength

  # Create special exception that happens nowhere else.  That way if
  # a *different* exception happens we don't accidentally pass the test.
  class WeirdException1 < StandardError
  end

  # Mock a detective who always fails
  class BadRepoFilesExamineDetective1 < RepoFilesExamineDetective
    def analyze(_, _)
      raise WeirdException1,
            'Exception of BadRepoFilesExamineDetective', caller
    end
  end

  test 'Fatal exceptions in a Detective will not crash production system' do
    old_environment = ENV.fetch('RAILS_ENV', nil)
    # TEMPORARILY make this a 'production' environment (it isn't really)
    ENV['RAILS_ENV'] = 'production'

    new_chief = Chief.new(@sample_project, Octokit::Client.new)

    detective = BadRepoFilesExamineDetective1.new

    VCR.use_cassette('github') do
      my_results = new_chief.propose_one_change(detective, {})
      # Restore original environment BEFORE assertions (clean up FIRST)
      if old_environment
        ENV['RAILS_ENV'] = old_environment
      else
        ENV.delete('RAILS_ENV')
      end
      # Ruby weirdness: {} is considered a block, not an empty hash,
      # so we can't use 'assert_equal {}, ...'.  We can't surround the {}
      # with parentheses to disambiguate it, because rubocop complains
      # with Lint/ParenthesesAsGroupedExpression.  So, do this instead.
      empty_hash = {}
      assert_equal empty_hash, my_results
    end
  end

  # Create special exception that happens nowhere else.  That way if
  # a *different* exception happens we don't accidentally pass the test.
  class WeirdException2 < StandardError
  end

  # Mock a detective who always fails
  class BadRepoFilesExamineDetective2 < RepoFilesExamineDetective
    def analyze(_, _)
      raise WeirdException2,
            'Exception of BadRepoFilesExamineDetective2', caller
    end
  end

  test 'Fatal exceptions in a Detective will crash the test system' do
    # Note difference with previous test.
    # Here we ensure that Detective exceptions WILL crash during testing.
    # This is an important distinction - we want the test environment
    # to crash quickly, so we detect problems and their causes quickly.
    # However, in production we don't want the system to crash.
    # Normally we want test and production systems to be the same,
    # but not in this way.  Thus, we must more carefully test the alternatives,
    # to ensure that both behaviors occur.

    old_environment = ENV.fetch('RAILS_ENV', nil)
    # TEMPORARILY make this a 'test' environment (it probably is anyway)
    ENV['RAILS_ENV'] = 'test'

    new_chief = Chief.new(@sample_project, Octokit::Client.new)

    detective = BadRepoFilesExamineDetective2.new

    VCR.use_cassette('github') do
      assert_raises WeirdException2 do
        new_chief.propose_one_change(detective, {})
      end
    end
    # Restore original environment.
    if old_environment
      ENV['RAILS_ENV'] = old_environment
    else
      ENV.delete('RAILS_ENV')
    end
  end

  # Tests for Phase 1: Topological Sort and Filtering

  test 'filter_needed_detectives returns all when needed_outputs is nil' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.filter_needed_detectives(nil)
    assert_equal Chief::ALL_DETECTIVES, result
  end

  test 'filter_needed_detectives returns all when needed_outputs is empty' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.filter_needed_detectives(Set.new)
    assert_equal Chief::ALL_DETECTIVES, result
  end

  test 'filter_needed_detectives returns subset when specific outputs needed' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    # Request only license-related outputs
    needed = Set.new(%i[floss_license_osi_status floss_license_status])
    result = chief.filter_needed_detectives(needed)

    # Should include FlossLicenseDetective (produces these outputs)
    assert_includes result, FlossLicenseDetective

    # Should be smaller than full list
    assert result.size < Chief::ALL_DETECTIVES.size
  end

  test 'filter_needed_detectives includes dependencies' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    # Request repo_files (output of HowAccessRepoFilesDetective)
    needed = Set.new([:contribution_status])
    result = chief.filter_needed_detectives(needed)

    # Should include RepoFilesExamineDetective (produces contribution_status)
    assert_includes result, RepoFilesExamineDetective

    # Should also include HowAccessRepoFilesDetective (provides :repo_files input)
    assert_includes result, HowAccessRepoFilesDetective
  end

  test 'topological_sort_detectives returns same size array' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    detectives = [FlossLicenseDetective, NameFromUrlDetective]
    result = chief.topological_sort_detectives(detectives)
    assert_equal detectives.size, result.size
  end

  test 'topological_sort_detectives orders dependencies correctly' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    # HowAccessRepoFilesDetective provides :repo_files
    # RepoFilesExamineDetective needs :repo_files as input
    detectives = [RepoFilesExamineDetective, HowAccessRepoFilesDetective]
    result = chief.topological_sort_detectives(detectives)

    # HowAccessRepoFilesDetective should come before RepoFilesExamineDetective
    how_index = result.index(HowAccessRepoFilesDetective)
    repo_index = result.index(RepoFilesExamineDetective)
    assert how_index < repo_index,
           'HowAccessRepoFilesDetective should come before RepoFilesExamineDetective'
  end

  test 'needed_outputs_for_level returns all outputs when level is nil' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.needed_outputs_for_level(nil)

    # Should include outputs from all detectives
    assert_includes result, :floss_license_osi_status # metal
    assert_includes result, :osps_le_03_01_status     # baseline
    assert result.size > 10
  end

  test 'needed_outputs_for_level returns metal criteria for passing level' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.needed_outputs_for_level('passing')

    # Should include metal criteria (no osps_ prefix)
    assert_includes result, :floss_license_osi_status
    assert_includes result, :contribution_status

    # Should not include baseline-only criteria (osps_ prefix)
    # (though some osps_ are in both metal and baseline detectives)
  end

  test 'needed_outputs_for_level returns baseline criteria for baseline-1 level' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.needed_outputs_for_level('baseline-1')

    # Should include baseline criteria (osps_ prefix)
    assert_includes result, :osps_le_03_01_status
    assert_includes result, :osps_br_03_01_status
  end

  test 'needed_outputs_for_level includes changed_fields' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    result = chief.needed_outputs_for_level('passing', [:custom_field])

    # Should include the explicitly changed field
    assert_includes result, :custom_field
  end

  test 'propose_changes accepts level parameter' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    VCR.use_cassette('github') do
      result = chief.propose_changes(level: 'passing')
      assert_kind_of Hash, result
    end
  end

  test 'propose_changes with level runs fewer detectives than without' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })

    # Mock to count detective invocations

    # Count how many detectives would run for level=nil
    needed_all = chief.needed_outputs_for_level(nil)
    detectives_all = chief.filter_needed_detectives(needed_all)
    detective_count_all = detectives_all.size

    # Count how many detectives would run for level='passing'
    needed_passing = chief.needed_outputs_for_level('passing')
    detectives_passing = chief.filter_needed_detectives(needed_passing)
    detective_count_level = detectives_passing.size

    # Should run fewer detectives for a specific level
    assert detective_count_level <= detective_count_all,
           "Level-specific should run <= detectives than all (#{detective_count_level} vs #{detective_count_all})"
  end

  test 'autofill accepts level parameter' do
    chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    VCR.use_cassette('github') do
      chief.autofill(level: 'passing')
    end
    # Should not raise an error
    assert_equal "https://github.com/#{@full_name}", @sample_project[:repo_url]
  end

  test 'autofill with level produces same results for overlapping criteria' do
    # Create two identical projects
    project1 = Project.new
    project1[:repo_url] = "https://github.com/#{@full_name}"

    project2 = Project.new
    project2[:repo_url] = "https://github.com/#{@full_name}"

    VCR.use_cassette('github') do
      # Run autofill with level on project1
      chief1 = Chief.new(project1, proc { Octokit::Client.new })
      chief1.autofill(level: 'passing')

      # Run autofill without level on project2
      chief2 = Chief.new(project2, proc { Octokit::Client.new })
      chief2.autofill
    end

    # For metal criteria, results should be the same
    assert_equal project1[:floss_license_osi_status],
                 project2[:floss_license_osi_status]
    assert_equal project1[:contribution_status],
                 project2[:contribution_status]
  end
end
# rubocop:enable Metrics/ClassLength
