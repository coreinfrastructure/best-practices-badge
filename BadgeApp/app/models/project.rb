class Project < ActiveRecord::Base
  validates :license, length: {minimum: 2}
end
