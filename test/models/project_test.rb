require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
    @user = users(:test_user)
    @project = @user.projects.build(project_url: 'https://www.example.org',
                                    repo_url: 'https://www.example.org/code')
  end

  test 'should be valid' do
    assert @project.valid?
  end

  test 'user id should be present' do
    @project.user_id = nil
    assert_not @project.valid?
  end
end
