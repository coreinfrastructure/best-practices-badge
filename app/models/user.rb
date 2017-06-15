# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class User < ApplicationRecord
  # Use Rails' "has_secure_password" so that local accounts' password is
  # is *only* stored as a bcrypt digest in password_digest
  # (an iterated per-use salted hash).  We want users to be able to edit
  # their profiles later, so disable the default password validation
  # since it interferes with editing (see "validates :password" below).
  has_secure_password validations: false

  has_many :projects, dependent: :destroy
  attr_accessor :remember_token, :activation_token, :reset_token
  before_create :create_activation_digest

  has_many :additional_rights

  # This is the minimum password length for *new* passwords. After increasing
  # this, users can log into existing user accounts even if they don't meet
  # this requirement.
  MIN_PASSWORD_LENGTH = 8

  # BCrypt hash function can handle maximum 72 characters, and if we pass
  # password of length more than 72 characters it ignores extra characters.
  # Hence there's a need to put a restriction on maximum password length.
  # This is an unfortunate limitation, but 72 characters is enough entropy
  # in practice.  See ActiveModel::SecurePassword.
  MAX_PASSWORD_LENGTH = 72

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    uniqueness: { case_sensitive: false }, email: true

  # Validate passwords; this is obviously security-related.
  # We directly control validations instead of using the default
  # validations in "has_secure_password", so that users can edit profiles.
  # In particular, we have to enable "confirmation: true" since that is
  # no longer checked by "has_secure_password".
  # The "allow_nil" means that updates may have an empty "password" field,
  # which will be interpreted as "do not change the password".
  # This is important for GitHub users, who don't give us passwords.
  # Non-nil passwords (which are *required* when creating a local account,
  # and also occur on password changes) must pass these validations,
  # including the bad-password check.
  validates :password,
            length: {
              minimum: MIN_PASSWORD_LENGTH,
              maximum: MAX_PASSWORD_LENGTH
            },
            password: true, # Apply special bad-password check
            confirmation: true,
            allow_nil: true

  # We don't allow locale nil. There's no need to, because the record has a
  # default value (and the default is used if we don't supply a value).
  VALID_LOCALES_STRINGS = I18n.available_locales.map(&:to_s)
  validates :preferred_locale, inclusion: { in: VALID_LOCALES_STRINGS }

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost =
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  def self.create_with_omniauth(auth)
    @user = User.new(
      provider: auth[:provider], uid: auth[:uid],
      name: auth[:info][:name], email: auth[:info][:email],
      nickname: auth[:info][:nickname], activated: true
    )
    @user.save!(validate: false)
    @user.send_github_welcome_email if @user.email
    @user
  end

  # Activates an account.
  def activate
    self.activated = true
    self.activated_at = Time.zone.now
    save!
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    self.reset_digest = User.digest(reset_token)
    self.reset_sent_at = Time.zone.now
    save!(touch: false)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Sends welcome email to GitHub users.
  def send_github_welcome_email
    UserMailer.github_welcome(self).deliver_now
  end

  def admin?
    role == 'admin'
  end

  # Returns a random token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions
  def remember
    self.remember_token = User.new_token
    self.remember_digest = User.digest(remember_token)
    save!(touch: false)
  end

  # Returns true if the given token matches the digest
  def authenticated?(attribute, token)
    digest = public_send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user
  def forget
    self.remember_digest = nil
    save!(validate: false, touch: false)
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Returns avatar URL
  def avatar_url
    if provider == 'github'
      "https://avatars.githubusercontent.com/#{nickname}?size=80"
    else
      avatar_id = Digest::MD5.hexdigest(email.downcase)
      "https://secure.gravatar.com/avatar/#{avatar_id}?d=mm&size=80"
    end
  end

  private

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
