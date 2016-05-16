# frozen_string_literal: true
class RenameOssToFloss < ActiveRecord::Migration
  def change
    rename_column :projects, :oss_license_status, :floss_license_status
    rename_column :projects,
                  :oss_license_justification,
                  :floss_license_justification
    rename_column :projects, :oss_license_osi_status, :floss_license_osi_status
    rename_column :projects,
                  :oss_license_osi_justification,
                  :floss_license_osi_justification
    rename_column :projects, :build_oss_tools_status, :build_floss_tools_status
    rename_column :projects,
                  :build_oss_tools_justification,
                  :build_floss_tools_justification
    rename_column :projects, :crypto_oss_status, :crypto_floss_status
    rename_column :projects,
                  :crypto_oss_justification,
                  :crypto_floss_justification
  end
end
