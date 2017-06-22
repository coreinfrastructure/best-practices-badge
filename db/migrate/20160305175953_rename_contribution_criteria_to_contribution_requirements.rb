# frozen_string_literal: true
class RenameContributionCriteriaToContributionRequirements <
      ActiveRecord::Migration[4.2]
  def change
    rename_column :projects,
                  :contribution_criteria_status,
                  :contribution_requirements_status
    rename_column :projects,
                  :contribution_criteria_justification,
                  :contribution_requirements_justification
  end
end
