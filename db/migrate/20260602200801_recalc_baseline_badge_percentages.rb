# frozen_string_literal: true

class RecalcBaselineBadgePercentages < ActiveRecord::Migration[8.0]
  def change
    # Baseline criteria set has changed (futures activated, obsoletes
    # removed), so stored badge_percentage_baseline_* values are stale.
    # Recalculate for all projects at all baseline levels.
    # update_all_badge_percentages also calls FastlyRails.purge_all,
    # so the CDN cache is cleared and badges update immediately.
    Project.update_all_badge_percentages(Sections::BASELINE_LEVEL_NAMES)
  end
end
