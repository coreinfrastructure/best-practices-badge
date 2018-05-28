# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class UserMailer < ApplicationMailer
  def account_activation(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: user.email,
        subject: t('user_mailer.account_activation.subject').strip
      )
    end
  end

  def password_reset(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: user.email,
        subject: t('user_mailer.password_reset.subject').strip
      )
    end
  end

  # Compute an array of valid destination email addresses, given a
  # new "email" value and the changes (which might
  # include the original email value).
  # Require that email addresses are non-null and include '@', and de-dup.
  def find_destinations(email, changes)
    destination = []
    destination << email if email&.include?('@')
    if changes && changes['email']
      old_email = changes['email'][0]
      destination << old_email if old_email&.include?('@')
    end
    destination.uniq
  end

  def user_update(user, changes)
    @user = user
    @changes = changes
    # If email changed, send to *all* email addresses (that way, if user
    # didn't approve this, the user will at least *see* the email change).
    destination = find_destinations(user&.email, changes)
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: destination,
        subject: t('user_mailer.user_update.subject').strip
      )
    end
  end

  def github_welcome(user)
    @user = user
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: user.email,
        subject: t('user_mailer.github_welcome.subject').strip
      )
    end
  end
end
