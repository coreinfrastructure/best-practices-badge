# frozen_string_literal: true

# Copyright 2015- the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

class PurgeCdnProjectJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:one)
  end

  test 'Purging CDN Project data' do
    assert_enqueued_jobs 0
    PurgeCdnProjectJob.set(wait: 24.hours).perform_later(@project)
    assert_enqueued_jobs 1
    PurgeCdnProjectJob.perform_now(@project)
  end
end
