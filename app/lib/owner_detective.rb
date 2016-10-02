# frozen_string_literal: true
# require 'json' # uncomment if you need to access GitHub

# WARNING: The JSON parser generates a 'normal' Ruby hash.
# Be sure to use strings, NOT symbols, as a key when accessing JSON-parsed
# results (because strings and symbols are distinct in basic Ruby).

class OwnerDetective < Detective
  # Individual detectives must identify their inputs, outputs
  INPUTS = %i(repo_url homepage_url name user_name user).freeze  # Input Hash required for Search
  OUTPUTS = [].freeze # Output Hash required to set database values.  Please see
  # database schema for allowed valuses to be set.
  # Setup and major work goes here.  Do not attempt to return anything from this
  # part of the code as it causes crashes.

  def analyze(_evidence, current)
    homepage_url = current[:homepage_url]
    repo_url = current[:repo_url]
    name = current[:name]
    user_name = current[:user_name]
    user = current[:user]
    puts "Owner Detective"
    puts user
    puts "**********************"
    puts user_name
    @results = {}
    {
      # Your return has to go here.  This reformats the hashed return into
      # chief understands.  Remember the output must corrospond to one of the
      # values in the database structure.
      # Typically This would be in the form.

      # blank_status:
      # {
      #  value: 'Met',  # or Unmet
      #  confidence: 3, # or what ever you think it should be.
      #  explanation: "My Text to appear in the evidence field"
      # }
    }
  end
end
