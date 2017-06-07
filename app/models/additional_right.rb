# frozen_string_literal: true

class AdditionalRight < ApplicationRecord
  # List additional rights of users for a given project.
  # This is a simple associative table (between project and user).
  # Currently mere *presence* is what matters; it gives the user edit rights
  # to that project.  In the future this *could* have 1+ additional fields
  # identifying the specific additional rights of a user over a project.
  belongs_to :project
  belongs_to :user
end
