# frozen_string_literal: true

class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user)
    @user = user
    mail to: user.email, subject: 'Account activation'
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    @user = user
    mail to: user.email, subject: 'Password reset'
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def user_update(user, changes)
    @user = user
    @changes = changes
    # If email changed, send to *both* email addresses (that way, if user
    # didn't approve this, the user will at least *see* the email change).
    destination = changes['email'] ? changes['email'] : user.email
    mail to: destination, subject: 'User data edited'
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.github_welcome.subject
  #
  def github_welcome(user)
    @user = user
    mail to: user.email, subject: 'Welcome to the Badging Program'
  end
end
