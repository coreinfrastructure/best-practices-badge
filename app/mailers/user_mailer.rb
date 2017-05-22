# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def account_activation(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail to: user.email, subject: t('user_mailer.account_activation.subject')
    end
  end

  def password_reset(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail to: user.email, subject: t('user_mailer.password_reset.subject')
    end
  end

  def user_update(user, changes)
    @user = user
    @changes = changes
    # If email changed, send to *both* email addresses (that way, if user
    # didn't approve this, the user will at least *see* the email change).
    destination = changes['email'] ? changes['email'] : user.email
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail to: destination, subject: t('user_mailer.user_update.subject')
    end
  end

  def github_welcome(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail to: user.email, subject: t('user_mailer.github_welcome.subject')
    end
  end
end
