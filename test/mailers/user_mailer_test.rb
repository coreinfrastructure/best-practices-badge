require 'test_helper'
class UserMailerTest < ActionMailer::TestCase
  test 'account_activation' do
    user = users(:test_user)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal 'Account activation', mail.subject
    assert_equal [user.email], mail.to
    assert_equal ['badgeapp@secret-retreat-6638.herokuapp.com'], mail.from
    assert_match user.activation_token, mail.body.encoded
    assert_match CGI.escape(user.email), mail.body.encoded
  end
end
