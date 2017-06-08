# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(
      name: 'Example User', email: 'user@example.com',
      provider: 'local',
      password: 'p@$$w0rd', password_confirmation: 'p@$$w0rd'
    )
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'name should be present' do
    @user.name = ''
    assert_not @user.valid?
  end

  test 'email should be present' do
    @user.email = ' '
    assert_not @user.valid?
  end

  test 'username should not be too long' do
    @user.name = 'a' * 51
    assert_not @user.valid?
  end

  test 'email should not be too long' do
    @user.email = 'e' * 250 + '@mail.com'
    assert_not @user.valid?
  end

  test 'email validation should accept good emails' do
    good_emails = %w[
      user@mail.com USER@foo.COM A_US-ER@abc.mail.org
      first.last@foo.co hello+bye@baz.uk
    ]
    good_emails.each do |good_email|
      @user.email = good_email
      assert @user.valid?, "#{good_email.inspect} should be valid"
    end
  end

  test 'email validation should reject bad emails' do
    bad_emails = %w[
      user@mail,com user_at_foo.org user.name@mail.
      foo@bar_baz.com foo@bar+baz.com
    ]
    bad_emails.each do |bad_email|
      @user.email = bad_email
      assert_not @user.valid?, "#{bad_email.inspect} should be invalid"
    end
  end

  test 'emails should be unique' do
    duplicate_user = @user.dup
    @user.save!
    assert_not duplicate_user.valid?
  end

  test 'emails should be unique when ignoring case' do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save!
    assert_not duplicate_user.valid?
  end

  # test 'password should be present and not empty' do
  #   @user.password = @user.password_confirmation = ' ' * 7
  #   assert_not @user.valid?
  # end

  test 'password should have a minimum length' do
    @user.password = @user.password_confirmation = 'a' * 7
    assert_not @user.valid?
  end

  test 'associated projects should be destroyed' do
    @user.save!
    @user.projects.create!(
      homepage_url: 'https://www.example.org',
      repo_url: 'https://www.example.org/code'
    )
    assert_difference 'Project.count', -1 do
      @user.destroy
    end
  end

  test 'authenticated? should return false for a user with nil digest' do
    assert_not @user.authenticated?(:remember, '')
  end

  test 'gravatar URL for local user' do
    avatar_id = Digest::MD5.hexdigest(users(:admin_user).email.downcase)
    assert_equal "https://secure.gravatar.com/avatar/#{avatar_id}?d=mm&size=80",
                 users(:admin_user).avatar_url
  end

  test 'gravatar URL for github user' do
    assert_equal 'https://avatars.githubusercontent.com/github-user?size=80',
                 users(:github_user).avatar_url
  end

  test 'Bcrypt of text with full rounds' do
    ActiveModel::SecurePassword.min_cost = false
    assert_match(/\$2a\$/, User.digest('foobar'))
    ActiveModel::SecurePassword.min_cost = true
  end
end
