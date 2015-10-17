class User < ActiveRecord::Base
  before_save { self.email = email.downcase }
  has_secure_password

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    email: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 7 }

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  def self.create_with_omniauth(auth)
    @user = User.new(provider: auth['provider'], uid: auth['uid'],
                     name: auth['info']['name'], email: auth['info']['email'],
                     nickname: auth['info']['nickname'])
    @user.save(validate: false)
    @user
  end
end
