require 'test_helper'

class ChiefTest < ActiveSupport::TestCase
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
  end

  test 'CII badge results correct' do
    new_chief = Chief.new(@sample_project)
    new_chief.autofill
    results = @sample_project

    assert_equal results[:license], 'MIT'
    assert_equal results[:name], @human_name
    assert_equal results[:oss_license_status], 'Met'
    assert_equal(
      results[:oss_license_justification],
      'The MIT license is approved by the Open Source Initiative (OSI).')
    assert_equal results[:oss_license_osi_status], 'Met'
    assert_equal(
      results[:oss_license_osi_justification],
      'The MIT license is approved by the Open Source Initiative (OSI).')
  end
end
