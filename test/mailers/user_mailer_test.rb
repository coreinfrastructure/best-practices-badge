# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
class UserMailerTest < ActionMailer::TestCase
  test 'account_activation' do
    user = users(:test_user_cs)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal 'Account activation', mail.subject
    assert_equal [user.email], mail.to
    assert_not_equal [user.email.downcase], mail.to
    assert_equal ['badgeapp@localhost'], mail.from
    assert_match user.activation_token, mail.body.encoded
    assert_match CGI.escape(user.email), mail.body.encoded
  end

  test 'password_reset' do
    user = users(:test_user_cs)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal 'Password reset', mail.subject
    assert_equal [user.email], mail.to
    assert_not_equal [user.email.downcase], mail.to
    assert_equal ['badgeapp@localhost'], mail.from
    assert mail.multipart?
    assert_equal ['text/plain; charset=UTF-8', 'text/html; charset=UTF-8'],
                 mail.parts.map(&:content_type)
    # Ensure that the reset token is actually being passed:
    assert_match user.reset_token, mail.parts[0].body.to_s
    assert_match CGI.escape(user.email), mail.body.encoded
  end

  test 'direct_message' do
    mail = UserMailer.direct_message(User.first, 'Dummy subject', 'Dummy body')
    assert_equal 'Dummy subject', mail.subject
    assert_equal [User.first.email], mail.to
  end
end
