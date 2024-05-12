# frozen_string_literal: true

# Copyright the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class PurgeCdnProjectJob < ApplicationJob
  queue_as :default

  def perform(project)
    # Send purge message to CDN
    project.purge_cdn_project
  end
end
