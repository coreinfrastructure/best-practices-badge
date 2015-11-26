require 'test_helper'

class ChiefTest < ActiveSupport::TestCase
  # rubocop:disable Metrics/MethodLength,Metrics/LineLength
  def setup
    @full_name = 'linuxfoundation/cii-best-practices-badge'
    @human_name = 'Core Infrastructure Initiative Best Practices Badge'

    @sample_project = Project.new
    @sample_project[:repo_url] = "https://github.com/#{@full_name}"

    stub_request(:get, "https://api.github.com/repos/#{@full_name}")
      .to_return(status: 200, headers: {},
                 body: '{ "description": "' + @human_name + '"}')

    stub_request(:get, "https://api.github.com/repos/#{@full_name}/license")
      .to_return(status: 200, headers: {},
                 body: '{ "license": { "key": "MIT" } }')

    stub_request(:get, "https://api.github.com/repos/#{@full_name}/contents/")
      .to_return(status: 200, headers: {}, body: '
      [
  {
    "name": "CHANGELOG.md",
    "path": "CHANGELOG.md",
    "sha": "0c5c52f14f821c6a5d7591f485624938838d7b9c",
    "size": 682,
    "url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/CHANGELOG.md?ref=master",
    "html_url": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/CHANGELOG.md",
    "git_url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/0c5c52f14f821c6a5d7591f485624938838d7b9c",
    "download_url": "https://raw.githubusercontent.com/linuxfoundation/cii-best-practices-badge/master/CHANGELOG.md",
    "type": "file",
    "_links": {
      "self": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/CHANGELOG.md?ref=master",
      "git": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/0c5c52f14f821c6a5d7591f485624938838d7b9c",
      "html": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/CHANGELOG.md"
    }
  },
  {
    "name": "CONTRIBUTING.md",
    "path": "CONTRIBUTING.md",
    "sha": "17131ab0d29a598bd4021e01adbf9404f8cda163",
    "size": 7618,
    "url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/CONTRIBUTING.md?ref=master",
    "html_url": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/CONTRIBUTING.md",
    "git_url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/17131ab0d29a598bd4021e01adbf9404f8cda163",
    "download_url": "https://raw.githubusercontent.com/linuxfoundation/cii-best-practices-badge/master/CONTRIBUTING.md",
    "type": "file",
    "_links": {
      "self": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/CONTRIBUTING.md?ref=master",
      "git": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/17131ab0d29a598bd4021e01adbf9404f8cda163",
      "html": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/CONTRIBUTING.md"
    }
  },
  {
    "name": "Rakefile",
    "path": "Rakefile",
    "sha": "dfa3aa4bfefd6dfba903204b63a615f94a23167e",
    "size": 251,
    "url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/Rakefile?ref=master",
    "html_url": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/Rakefile",
    "git_url": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/dfa3aa4bfefd6dfba903204b63a615f94a23167e",
    "download_url": "https://raw.githubusercontent.com/linuxfoundation/cii-best-practices-badge/master/Rakefile",
    "type": "file",
    "_links": {
      "self": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/contents/Rakefile?ref=master",
      "git": "https://api.github.com/repos/linuxfoundation/cii-best-practices-badge/git/blobs/dfa3aa4bfefd6dfba903204b63a615f94a23167e",
      "html": "https://github.com/linuxfoundation/cii-best-practices-badge/blob/master/Rakefile"
    }
  }
      ]
   ')
  end

  test 'CII badge results correct' do
    new_chief = Chief.new(@sample_project)
    new_chief.autofill
    results = @sample_project

    skip 'Temporarily skip while debugging website problem.'
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
end
