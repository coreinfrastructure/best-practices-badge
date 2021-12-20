# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
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
    # Ensure that email has settings to disable tracking and delay sending
    assert_not_nil mail['X-SMTPAPI'].unparsed_value
    extensions = JSON.parse(mail['X-SMTPAPI'].unparsed_value)
    assert_includes extensions, 'send_at'
    assert extensions['send_at'] > Time.now.utc.to_i
    assert_includes extensions, 'filters'
    disable = { 'settings' => { 'enable' => 0 } }
    assert_equal disable, extensions['filters']['clicktrack']
    assert_equal disable, extensions['filters']['opentrack']
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
    # Ensure that email has settings to disable tracking
    assert_not_nil mail['X-SMTPAPI'].unparsed_value
    extensions = JSON.parse(mail['X-SMTPAPI'].unparsed_value)
    assert_not_includes extensions, 'send_at'
    assert_includes extensions, 'filters'
    disable = { 'settings' => { 'enable' => 0 } }
    assert_equal disable, extensions['filters']['clicktrack']
    assert_equal disable, extensions['filters']['opentrack']
  end

  test 'direct_message' do
    mail = UserMailer.direct_message(User.first, 'Dummy subject', 'Dummy body')
    assert_equal 'Dummy subject', mail.subject
    assert_equal [User.first.email], mail.to
  end
end
