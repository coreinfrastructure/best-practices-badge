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

  # Returns the hash digest of the given string using BCrypt.
  # Uses minimum cost for testing, normal cost for production.
  # @param string [String] the string to hash
  # @return [String] BCrypt hash digest of the string
  def self.digest(string)
    cost =
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  # Verifies a password against a BCrypt hash in a centralized location.
  # This method encapsulates the password verification algorithm so it can be
  # easily changed in the future if needed.
  #
  # @param hash_digest [String] The BCrypt hash digest to verify against
  # @param password [String] The password to verify
  # @return [Boolean] True if password matches the hash, false otherwise
  def self.verify_password_against_hash?(hash_digest, password)
    BCrypt::Password.new(hash_digest).is_password?(password)
  end

  # Dummy value used to do extra work when there's no user.
  # This way attackers can't determine, through timing, if a user is present
  # in the database. The value being digested is irrelevant, because when
  # this hash value is used we will *always* reject the request eventually.
  DUMMY_HASH = digest('dummy_password_for_timing_protection')

  # Authenticates a local user by email and password in constant time.
  # This prevents timing attacks from enumerating present email addresses.
  # Returns the authenticated user if credentials are valid, nil otherwise.
  #
  # @param email [String] The user's email address
  # @param password [String] The user's password
  # @return [User, nil] The authenticated user or nil if authentication fails
  def self.authenticate_local_user(email, password)
    user = find_by(provider: 'local', email: email)

    if user
      # User exists, verify against their actual password hash
      authenticated = user.authenticate(password)
    else
      # User doesn't exist in our database. Perform a dummy verification
      # (whose result we will ignore) prevent
      # timing attacks from revealing that the user is not present in
      # our database.
      verify_password_against_hash?(DUMMY_HASH, password)
      authenticated = false
    end

    # Only return the user if both user exists AND authentication succeeded
    user if user && authenticated
  end

  # Creates a new user from OAuth authentication data.
  # Sets the user as activated and sends a welcome email if email is provided.
  # @param auth [Hash] OAuth authentication hash containing provider, uid, info
  # @return [User] the created and saved user instance
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

  # Activates an account by setting activated flag and timestamp.
  # @return [Boolean] true if save was successful
  def activate
    self.activated = true
    self.activated_at = Time.zone.now
    save!
  end

  # Sends activation email and records the time sent to limit resends.
  # @return [Boolean] true if save was successful
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
    self.activation_email_sent_at = Time.zone.now
    save!(touch: false)
  end

  # Sets the password reset attributes including token, digest, and timestamp.
  # @return [Boolean] true if save was successful
  def create_reset_digest
    self.reset_token = User.new_token
    self.reset_digest = User.digest(reset_token)
    self.reset_sent_at = Time.zone.now
    save!(touch: false)
  end

  # Sends password reset email to the user.
  # @return [Mail::Message] the delivered email message
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Sends welcome email to GitHub users.
  # @return [Mail::Message] the delivered email message
  def send_github_welcome_email
    UserMailer.github_welcome(self).deliver_now
  end

  # Returns the decrypted email address or error message if decryption fails.
  # @return [String] the email address or 'CANNOT_DECRYPT' if decryption fails
  def email_if_decryptable
    email
  rescue OpenSSL::Cipher::CipherError
    'CANNOT_DECRYPT'
  end

  # Checks if the user has admin role.
  # @return [Boolean] true if user role is 'admin'
  def admin?
    role == 'admin'
  end

  # Checks if the user is allowed to login now.
  # Returns true if can_login_starting_at is null or has passed.
  # Returns false if we are still in cooloff period or account is unactivated.
  # @return [Boolean] true if login is allowed now
  def login_allowed_now?
    return false unless activated?

    start_time = can_login_starting_at
    start_time.blank? || Time.zone.now >= start_time
  end

  # Generates a new random URL-safe base64 token.
  # @return [String] a random URL-safe base64 encoded token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  # Generates and stores a remember token and its digest.
  # @return [Boolean] true if save was successful
  def remember
    self.remember_token = User.new_token
    self.remember_digest = User.digest(remember_token)
    save!(touch: false)
  end

  # Checks if the given token matches the stored digest for the specified attribute.
  # @param attribute [String, Symbol] the attribute name (e.g., 'remember', 'activation')
  # @param token [String] the token to verify
  # @return [Boolean] true if token matches the digest
  def authenticated?(attribute, token)
    digest = public_send(:"#{attribute}_digest")
    return false if digest.nil?

    User.verify_password_against_hash?(digest, token)
  end

  # Forgets a user by clearing the remember digest.
  # @return [Boolean] true if save was successful
  def forget
    self.remember_digest = nil
    save!(validate: false, touch: false)
  end

  # Checks if a password reset request has expired (older than 2 hours).
  # @return [Boolean] true if password reset has expired
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Re-encrypts the user's email address with a new encryption key.
  # Note that this will reset the IV, since we do *NOT* want to reuse IVs.
  # This does not SAVE the user data - do a save afterwards if you want that!
  # This will raise an exception if the old key doesn't work.
  # @param old_key [String] the old encryption key used to decrypt the email
  # @return [void]
  # @raise [OpenSSL::Cipher::CipherError] if the old key is incorrect
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

  # Returns URL for Gravatar lookup based on email MD5 hash.
  # This is the real Gravatar URL used for local users.
  # @return [String] the Gravatar URL for lookup
  def lookup_gravatar_url
    GRAVATAR_PREFIX + Digest::MD5.hexdigest(email.downcase)
  end

  BOGUS_GRAVATAR_MD5 = '0' * 32

  # Returns URL for Gravatar image suitable for public sharing.
  # Uses real Gravatar URL if use_gravatar is true, otherwise uses bogus hash.
  # This prevents sharing the email MD5 unless explicitly allowed.
  # @return [String] the public-safe Gravatar URL
  def revealable_gravatar_url
    if use_gravatar
      lookup_gravatar_url
    else
      GRAVATAR_PREFIX + BOGUS_GRAVATAR_MD5
    end
  end

  # Returns avatar URL for use in img src attribute.
  # Returns GitHub avatar for GitHub users, Gravatar for others.
  # This URL must return an image with the correct size (80px).
  # @return [String] the avatar URL
  def avatar_url
    if provider == 'github'
      "https://avatars.githubusercontent.com/#{nickname}?size=80"
    else
      revealable_gravatar_url + '?d=mm&size=80'
    end
  end

  # Checks if a Gravatar exists for this user's email address.
  # Uses HTTP HEAD request with ?d=404 to force 404 if no Gravatar exists.
  # @return [Boolean] true if Gravatar exists
  def gravatar_exists?
    # The ?d=404 forces "not found" error code if none is found.
    # We use "head" because we don't need the full data at this point.
    response = HTTParty.head(lookup_gravatar_url + '?d=404')
    # Assume we won't be redirected if something is found, so the
    # only thing we care about is if we get 200 (success) or not.
    response.code == 200
  end

  # Creates and assigns the activation token and digest for email verification.
  # Called before user creation to set up account activation.
  # @return [void]
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
# rubocop:enable Metrics/ClassLength
