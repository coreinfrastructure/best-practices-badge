# frozen_string_literal: true
# require 'json' # uncomment if you need to access GitHub

# If it's a GitHub repo, grab easily-acquired data from GitHub API and
# use it to determine key values for project.

# WARNING: The JSON parser generates a 'normal' Ruby hash.
# Be sure to use strings, NOT symbols, as a key when accessing JSON-parsed
# results (because strings and symbols are distinct in basic Ruby).

# rubocop:disable Metrics/ClassLength
class BlankDetective < Detective
  # Individual detectives must identify their inputs, outputs
  INPUTS = [].freeze  #Input Hash required for Search
  OUTPUTS = [].freeze #Onput Hash required to set database values.  Please see
  # database schema for allowed valuses to be set.


  def analyze(_evidence, current)
  {
    # Your return has to go here.
  }
  end
end
