# A 'Detective' (analyzer) analyzes data from evidence and reports
# what it believes the new values should be.
# This is subclassed (one per each analyzer); an instance analyzes 1 project.
# Only the 'chief' decides when to update the proposed changes.

class Detective
  # Individual detectives must identify their inputs, outputs
  INPUTS = []
  OUTPUTS = []

  # Individual detectives must implement "analyze"
  # "Current" is a hash of current best estimates of fields and values.
  # We pass this separately from the evidence to reduce potential problems
  # from parallel execution (if we add that later).
  def analyze(_evidence, _current)
  end
end
