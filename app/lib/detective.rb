# A 'Detective' (analyzer) analyzes data from evidence and reports
# what it believes the new values should be.
# This is subclassed (one per each analyzer).
# Only the 'chief' decides when to update the proposed changes.

class Detective
  # Individual detectives must identify their inputs, outputs

  # Individual detectives must implement "analyze"
  def analyze(_evidence)
  end
end
