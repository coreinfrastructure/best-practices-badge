# frozen_string_literal: true

class User < ActiveRecord::Base
  has_secure_password
  has_many :projects, dependent: :destroy
  attr_accessor :remember_token, :activation_token, :reset_token
  before_create :create_activation_digest

  # This is the minimum password length for *new* passwords. After increasing
  # this, users can log into existing user accounts even if they don't meet
  # this requirement.
  MIN_PASSWORD_LENGTH = 8

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    uniqueness: { case_sensitive: false }, email: true
  validates :password, presence: true,
                       length: { minimum: MIN_PASSWORD_LENGTH },
                       password: true,
                       allow_nil: true

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
    digest = send("#{attribute}_digest")
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
