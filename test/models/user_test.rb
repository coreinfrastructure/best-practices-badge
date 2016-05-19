# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: 'Example User', email: 'user@example.com',
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
    good_emails = %w(
      user@mail.com USER@foo.COM A_US-ER@abc.mail.org
      first.last@foo.co hello+bye@baz.uk
    )
    good_emails.each do |good_email|
      @user.email = good_email
      assert @user.valid?, "#{good_email.inspect} should be valid"
    end
  end

  test 'email validation should reject bad emails' do
    bad_emails = %w(
      user@mail,com user_at_foo.org user.name@mail.
      foo@bar_baz.com foo@bar+baz.com
    )
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

  test 'password should be present and not empty' do
    @user.password = @user.password_confirmation = ' ' * 6
    assert_not @user.valid?
  end

  test 'password should have a minimum length' do
    @user.password = @user.password_confirmation = 'a' * 6
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

  test 'Bcrypt of text with full rounds' do
    ActiveModel::SecurePassword.min_cost = false
    assert_match(/\$2a\$/, User.digest('foobar'))
    ActiveModel::SecurePassword.min_cost = true
  end
end
