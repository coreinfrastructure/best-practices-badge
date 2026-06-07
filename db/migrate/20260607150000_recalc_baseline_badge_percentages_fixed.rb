# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

class RecalcBaselineBadgePercentagesFixed < ActiveRecord::Migration[8.1]
  def change
    # Re-run the baseline badge percentage recalculation.
    # This time it uses the updated Project.update_all_badge_percentages
    # which skips validations, ensuring it completes even for projects
    # with data that is now considered 'invalid' (e.g., legacy IP-based URLs).
    Project.update_all_badge_percentages(Sections::BASELINE_LEVEL_NAMES)
  end
end
