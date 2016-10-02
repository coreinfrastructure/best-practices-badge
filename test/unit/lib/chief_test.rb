# frozen_string_literal: true
require 'test_helper'

class ChiefTest < ActiveSupport::TestCase
  def setup
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'

    @sample_project = Project.new
    @sample_project[:repo_url] = "https://github.com/#{@full_name}"
  end

  test 'CII badge results correct' do
    new_chief = Chief.new(@sample_project, proc { Octokit::Client.new })
    VCR.use_cassette('github') do
      new_chief.autofill
    end
    results = @sample_project

    # skip 'Temporarily skip while debugging website problem.'
    mit_ok = 'The MIT license is approved by the Open Source Initiative (OSI).'
    assert_equal 'MIT', results[:license]
    assert_equal @human_name, results[:name]
    assert_equal 'Met', results[:floss_license_status]
    assert_equal mit_ok, results[:floss_license_justification]
    assert_equal 'Met', results[:floss_license_osi_status]
    assert_equal mit_ok, results[:floss_license_osi_justification]
    assert_equal 'Met', results[:contribution_status]
    assert_equal 'Non-trivial contribution file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/CONTRIBUTING.md>.',
                 results[:contribution_justification]
    assert_equal 'Met', results[:release_notes_status]
    assert_equal 'Non-trivial release notes file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/CHANGELOG.md>.',
                 results[:release_notes_justification]
    assert_equal 'Met', results[:build_status]
    assert_equal 'Non-trivial build file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/Rakefile>.',
                 results[:build_justification]
  end

  test 'Fatal exceptions in a Detective will not crash production system' do
    old_environment = ENV['RAILS_ENV']
    # TEMPORARILY make this a 'production' environment (it isn't really)
    ENV['RAILS_ENV'] = 'production'

    new_chief = Chief.new(@sample_project, Octokit::Client.new)

    # Create special exception that happens nowhere else.  That way if
    # a *different* exception happens we don't accidentally pass the test.
    class WeirdException < StandardError
    end
    # Mock a detective who always fails
    class BadRepoFilesExamineDetective < RepoFilesExamineDetective
      def analyze(_, _)
        raise WeirdException,
              'Exception of BadRepoFilesExamineDetective', caller
      end
    end
    detective = BadRepoFilesExamineDetective.new

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

  test 'Fatal exceptions in a Detective will crash the test system' do
    # Note difference with previous test.
    # Here we ensure that Detective exceptions WILL crash during testing.
    # This is an important distinction - we want the test environment
    # to crash quickly, so we detect problems and their causes quickly.
    # However, in production we don't want the system to crash.
    # Normally we want test and production systems to be the same,
    # but not in this way.  Thus, we must more carefully test the alternatives,
    # to ensure that both behaviors occur.

    old_environment = ENV['RAILS_ENV']
    # TEMPORARILY make this a 'test' environment (it probably is anyway)
    ENV['RAILS_ENV'] = 'test'

    new_chief = Chief.new(@sample_project, Octokit::Client.new)

    # Create special exception that happens nowhere else.  That way if
    # a *different* exception happens we don't accidentally pass the test.
    class WeirdException < StandardError
    end
    # Mock a detective who always fails
    class BadRepoFilesExamineDetective < RepoFilesExamineDetective
      def analyze(_, _)
        raise WeirdException,
              'Exception of BadRepoFilesExamineDetective', caller
      end
    end
    detective = BadRepoFilesExamineDetective.new

    VCR.use_cassette('github') do
      assert_raises WeirdException do
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
end
