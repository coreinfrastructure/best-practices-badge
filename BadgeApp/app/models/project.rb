class Project < ActiveRecord::Base
  validates :license, length: {minimum: 2}

  STATUS_CHOICE = ['', 'Met', 'Not Met']
end
