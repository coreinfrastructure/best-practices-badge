require 'open-uri'

class Evidence
  # This class collects and caches all evidence gathered so far on a project.
  # If parallel execution is possible, this class locks/unlocks so
  # parallel writing doesn't cause any harm.

  # NOTE: The current plan is to remove this class, it's not helping much.

  def initialize(project)
    @project = project # ActiveRecord. Detectives should NOT change this.
    @cached_data = {}
  end

  attr_reader :project

  # Don't download more than this number of bytes per file;
  # this helps counter easy DoS attacks.
  MAXREAD = 1 * (2**20)

  # Get contents of given URL and return it (cached).
  # TODO: Handle exceptions - turn into nothing useful.
  # TODO: Lock for parallel access. Possibly return while still reading.
  # TODO: Timeout on reads.
  def get(url)
    unless @cached_data.key?(url)
      open(url, 'rb') do |file|
        @cached_data[url] = file.read(MAXREAD)
      end
    end
    @cached_data[url]
  end
end
