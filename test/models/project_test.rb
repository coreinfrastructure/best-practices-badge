require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @project = @user.projects.build(
      project_homepage_url: 'https://www.example.org',
      repo_url: 'https://www.example.org/code')
  end

  test 'should be valid' do
    assert @project.valid?
  end

  test 'user id should be present' do
    @project.user_id = nil
    assert_not @project.valid?
  end

  test '#contains_url?' do
    assert Project.new.send :contains_url?, 'https://www.example.org'
    assert Project.new.send :contains_url?, 'http://www.example.org'
    refute Project.new.send :contains_url?, 'mailto://mail@example.org'
    refute Project.new.send :contains_url?, 'abc'
  end
end
