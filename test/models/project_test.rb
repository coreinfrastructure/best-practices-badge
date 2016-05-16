# frozen_string_literal: true
require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @project = @user.projects.build(
      homepage_url: 'https://www.example.org',
      repo_url: 'https://www.example.org/code'
    )
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
    refute Project.new.contains_url? 'mailto://mail@example.org'
    refute Project.new.contains_url? 'abc'
    refute Project.new.contains_url? 'See also http://x for more information.'
    refute Project.new.contains_url? 'www.google.com'
  end

  test 'Rigorous project and repo URL checker' do
    regex = UrlValidator::URL_REGEX
    my_url = 'https://github.com/linuxfoundation/cii-best-practices-badge'
    assert my_url =~ regex
    assert 'https://kernel.org' =~ regex
    refute 'https://' =~ regex
    refute 'www.google.com' =~ regex
    refute 'See also http://x.org for more information.' =~ regex
    refute 'See also <http://x.org>.' =~ regex
  end
end
