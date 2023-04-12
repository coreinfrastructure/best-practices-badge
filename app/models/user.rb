# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
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

  has_many :additional_rights, dependent: :destroy

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

  # We use hexadecimal encoding (0010=\x00\x10), NOT Base64 or other
  DIGITS_OF_EMAIL_ENCRYPTION_KEY = 256 / 8 * 2 # 256-bit AES key in hex
  DIGITS_OF_EMAIL_BLIND_INDEX_KEY = 256 / 8 * 2 # 256-bit HMAC key in hex

  # For tests
  TEST_EMAIL_ENCRYPTION_KEY = '1' * DIGITS_OF_EMAIL_ENCRYPTION_KEY
  TEST_EMAIL_BLIND_INDEX_KEY = '2' * DIGITS_OF_EMAIL_BLIND_INDEX_KEY

  # Email addresses are stored as encrypted values.
  # If a key isn't provided, use a bogus one to make testing easy.
  attr_encrypted :email, algorithm: 'aes-256-gcm', key: [
    ENV['EMAIL_ENCRYPTION_KEY'] || TEST_EMAIL_ENCRYPTION_KEY
  ].pack('H*')

  # Email addresses are indexed as blind indexes of downcased email addresses,
  # so we can efficiently search for them while keeping them encrypted.
  # Usage: User.where(email: 'test@example.org')
  # or:    User.where(email: 'test@example.org', provider: 'local')
  blind_index :email, key: [
    ENV['EMAIL_BLIND_INDEX_KEY'] || TEST_EMAIL_BLIND_INDEX_KEY
  ].pack('H*'), expression: ->(v) { v.try(:downcase) }

  scope :created_since, (
    lambda do |time|
      where(User.arel_table[:created_at].gteq(time))
    end
  )

  scope :updated_since, (
    lambda do |time|
      where(User.arel_table[:created_at].gteq(time))
    end
  )

  validates :name, presence: true, length: { maximum: 50 }

  validates :email, presence: true, length: { maximum: 255 }, email: true

  # We check uniqueness of local account email addresses *both* here in
  # the model *and* also directly in the database (via unique_local_email).
  # The uniqueness check here in the model provides better error messages
  # and works regardless of the underlying RDBMS.  The RDBMS-level index
  # check, however, is immune to races where supported (PostgreSQL does),
  # because the RDBMS is the final arbiter.
  validates :email, uniqueness: { scope: :provider, case_sensitive: false },
                    if: ->(u) { u.provider == 'local' }

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

  def email_if_decryptable
    email
  rescue OpenSSL::Cipher::CipherError
    'CANNOT_DECRYPT'
  end

  def admin?
    role == 'admin'
  end

  # Return "true" if can_login_starting_at for this user is null or has passed.
  # Return "false" otherwise (that is, if we are still cooling off)
  # Always return "false" for an unactivated account.
  def login_allowed_now?
    return false unless activated?

    start_time = can_login_starting_at
    start_time.blank? || Time.zone.now >= start_time
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

  # Rekey (change the key of) the email address of the user, given the old key.
  # Note that this will reset the IV, since we do *NOT* want to reuse IVs.
  # This does not SAVE the user data - do a save afterwards if you want that!
  # This will raise an exception if the old key doesn't work.
  def rekey(old_key)
    return if encrypted_email_iv.blank? || encrypted_email.blank?

    old_iv = Base64.decode64(encrypted_email_iv)
    # Get the old email address; this will raise an exception if the
    # given key is wrong.
    old_email_address = User.decrypt_email(
      encrypted_email, iv: old_iv, key: old_key
    )
    # Change to new email address; this creates a new IV, re-encrypts,
    # and recalculates the blind index using the current blind index key.
    # This deals with a quirk of attr_encrypted: You have to set the
    # old encrypted_mail value to nil before you can force a re-encrypt.
    self.encrypted_email = nil
    self.email = old_email_address
  end

  GRAVATAR_PREFIX = 'https://secure.gravatar.com/avatar/'

  # Return URL for an image suitable for doing a lookup on gravatar
  # (used for local users).  This is the *real* one based on the email MD5
  def lookup_gravatar_url
    GRAVATAR_PREFIX + Digest::MD5.hexdigest(email.downcase)
  end

  BOGUS_GRAVATAR_MD5 = '0' * 32

  # Return URL for an image suitable for sharing to the public as a gravatar
  # URL.  This will NOT share the MD5 unless we're to use it.
  def revealable_gravatar_url
    if use_gravatar
      lookup_gravatar_url
    else
      GRAVATAR_PREFIX + BOGUS_GRAVATAR_MD5
    end
  end

  # Returns avatar URL, for use in img src="...". This URL must
  # return an image with the correct size.
  def avatar_url
    if provider == 'github'
      "https://avatars.githubusercontent.com/#{nickname}?size=80"
    else
      revealable_gravatar_url + '?d=mm&size=80'
    end
  end

  # Return true if there's a gravatar for this user
  def gravatar_exists
    # The ?d=404 forces "not found" error code if none is found.
    # We use "head" because we don't need the full data at this point.
    response = HTTParty.head(lookup_gravatar_url + '?d=404')
    # Assume we won't be redirected if something is found, so the
    # only thing we care about is if we get 200 (success) or not.
    response.code == 200
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
# rubocop:enable Metrics/ClassLength
