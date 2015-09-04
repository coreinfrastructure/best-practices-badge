class User < ActiveRecord::Base
  before_save { self.email = email.downcase }
  validates :name, presence: true, length: {maximum: 50}
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: {maximum: 255},
                    format: { with: email_regex },
                    uniqueness: {case_sensitive: false}

  has_secure_password
  validates :password, presence: true, length: {minimum: 7}

end
