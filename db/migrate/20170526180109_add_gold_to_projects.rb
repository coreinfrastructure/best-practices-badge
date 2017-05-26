# frozen_string_literal: true

class AddGoldToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :badge_percentage_2, :integer, default: 0

    add_column :projects, :contributors_unassociated_status, :string, default: '?'
    add_column :projects, :contributors_unassociated_justification, :text

    add_column :projects, :copyright_per_file_status, :string, default: '?'
    add_column :projects, :copyright_per_file_justification, :text

    add_column :projects, :license_per_file_status, :string, default: '?'
    add_column :projects, :license_per_file_justification, :text

    add_column :projects, :small_tasks_status, :string, default: '?'
    add_column :projects, :small_tasks_justification, :text

    add_column :projects, :require_2FA_status, :string, default: '?'
    add_column :projects, :require_2FA_justification, :text

    add_column :projects, :secure_2FA_status, :string, default: '?'
    add_column :projects, :secure_2FA_justification, :text

    add_column :projects, :code_review_standards_status, :string, default: '?'
    add_column :projects, :code_review_standards_justification, :text

    add_column :projects, :two_person_review_status, :string, default: '?'
    add_column :projects, :two_person_review_justification, :text

    add_column :projects, :test_statement_coverage90_status, :string, default: '?'
    add_column :projects, :test_statement_coverage90_justification, :text

    add_column :projects, :test_branch_coverage80_status, :string, default: '?'
    add_column :projects, :test_branch_coverage80_justification, :text

    add_column :projects, :security_review_status, :string, default: '?'
    add_column :projects, :security_review_justification, :text
  end
end
