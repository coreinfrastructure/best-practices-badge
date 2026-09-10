# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# A stashed form submission from a logged-out submitter, awaiting re-login.
# See docs/login-session-implementation.md section 15 for the full design.
# No custom methods needed: every use (create!, find_by, destroy, the daily
# cleanup's delete_all) is plain ActiveRecord.
class PendingResubmission < ApplicationRecord
end
