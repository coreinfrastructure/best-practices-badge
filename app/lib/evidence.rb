# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'open-uri'
require 'security_utils'

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
  # rubocop:disable Metrics/MethodLength
  def get(url)
    return if url.blank?

    unless @cached_data.key?(url)
      # Security: Ignore dubious URLs (SSRF protection & professional standards)
      if SecurityUtils.dubious_url?(url)
        Rails.logger.warn "Ignoring dubious URL for evidence: #{url}"
        @cached_data[url] = nil
        return
      end

      begin
        URI.parse(url).open('rb') do |file|
          @cached_data[url] = { meta: file.meta, body: file.read(MAXREAD) }
        end
      rescue
        # Skip if error - use what we have, if anything.
        @cached_data[url] ||= nil
      end
    end
    @cached_data[url]
  end
  # rubocop:enable Metrics/MethodLength
end
