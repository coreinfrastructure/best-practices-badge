require 'test_helper'

class ChiefTest < ActiveSupport::TestCase
  def setup
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'

    @sample_project = Project.new
    @sample_project[:repo_url] = "https://github.com/#{@full_name}"
  end

  test 'CII badge results correct' do
    new_chief = Chief.new(@sample_project)
    VCR.use_cassette('github') do
      new_chief.autofill
    end
    results = @sample_project

    # skip 'Temporarily skip while debugging website problem.'
    mit_ok = 'The MIT license is approved by the Open Source Initiative (OSI).'
    assert_equal 'MIT', results[:license]
    assert_equal @human_name, results[:name]
    assert_equal 'Met', results[:oss_license_status]
    assert_equal mit_ok, results[:oss_license_justification]
    assert_equal 'Met', results[:oss_license_osi_status]
    assert_equal mit_ok, results[:oss_license_osi_justification]
    assert_equal 'Met', results[:contribution_status]
    assert_equal 'Non-trivial contribution file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/CONTRIBUTING.md>.',
                 results[:contribution_justification]
    assert_equal 'Met', results[:changelog_status]
    assert_equal 'Non-trivial changelog file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/CHANGELOG.md>.',
                 results[:changelog_justification]
    assert_equal 'Met', results[:build_status]
    assert_equal 'Non-trivial build file in repository: ' \
                 '<https://github.com/linuxfoundation/' \
                 'cii-best-practices-badge/blob/master/Rakefile>.',
                 results[:build_justification]
  end

  test 'Fatal exceptions in a Detective will not crash the system' do
    old_environment = ENV['RAILS_ENV']
    # TEMPORARILY make this a 'production' environment (it isn't really)
    ENV['RAILS_ENV'] = 'production'

    new_chief = Chief.new(@sample_project)

    # Mock a detective who always fails
    class BadRepoFilesExamineDetective < RepoFilesExamineDetective
      def analyze(_, _)
        fail StandardError, 'Exception of BadRepoFilesExamineDetective', caller
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
      # with parentheses to disambiguate, because rubocop complains.
      # with Lint/ParenthesesAsGroupedExpression.  So do this instead.
      empty_hash = {}
      assert_equal empty_hash, my_results
    end
  end
end
