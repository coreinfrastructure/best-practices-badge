class Project < ActiveRecord::Base
  STATUS_CHOICE = ['?', 'Met', 'Unmet']

  validates_inclusion_of :license_location_status, :in => STATUS_CHOICE, :allow_nil => true
  validates_inclusion_of :oss_license_status, :in => STATUS_CHOICE, :allow_nil => true
  validates_inclusion_of :oss_license_osi_status, :in => STATUS_CHOICE, :allow_nil => true

end
