# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
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
    @user.email = ('e' * 250) + '@mail.com'
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

  test 'rekey test' do
    # This is a somewhat complicated setup to create a user with an old key.
    # We don't bother setting up an old blind index, because we're going
    # to just obliterate it anyway.
    user1 = User.new
    # Set a different email address to initialize attr_encrypted
    user1.email = 'wrong_email'
    # Now insert some encrypted data using an "old" key
    old_key = ['ea' * 32].pack('H*')
    old_iv = Base64.decode64(user1.encrypted_email_iv)
    email_address = 'bogus@stuff.com'
    user1.encrypted_email = User.encrypt_email(
      email_address,
      key: old_key, iv: old_iv
    )
    # Setup done, now invoke rekey to test rekeying the record.
    user1.rekey(old_key)
    # Check if rekey results are correct
    assert email_address, user1.email
    new_blind_index = BlindIndex.generate_bidx( # Recalc so test's less fragile
      email_address,
      key: [User::TEST_EMAIL_BLIND_INDEX_KEY].pack('H*'),
      options: User.blind_indexes[:email]
    )
    assert new_blind_index, user1.email_bidx
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

  class StubUserEmail < User
    def email
      raise OpenSSL::Cipher::CipherError
    end
  end

  test 'Test user.email_if_decryptable when not decryptable' do
    u = StubUserEmail.new
    assert_equal 'CANNOT_DECRYPT', u.email_if_decryptable
  end

  test 'Data model encrypted email addresses and blind index keys work' do
    # We precompute the user data fixtures, and it's possible we got it wrong.
    # Walk through the data set to do sanity checks for each value.
    User.find_each do |user|
      # puts(user.name)
      assert user.name.present?, "Empty name for #{user.id}"
      assert user.encrypted_email.present?,
             "Email not present for #{user.name}"
      assert(
        user.encrypted_email_iv.present?,
        "Email IV not present for #{user.name}"
      )
      # This will also fail if the email is not encrypted correctly:
      assert user.email.present?, "Email not present for #{user.name}"
      assert user.provider.present?, "Provider not present for #{user.name}"
      assert(
        (user.provider != 'local' || user.password_digest.present?),
        "Local user has no password: #{user.name}, #{user.email}"
      )
      # An incorrect bidx could lead to confusing test results, so we
      # *definitely* want the following check.
      # Check that bidx was computed correctly:
      assert_equal User.generate_email_bidx(user.email), user.email_bidx
    end
  end
end
# rubocop:enable Metrics/ClassLength
