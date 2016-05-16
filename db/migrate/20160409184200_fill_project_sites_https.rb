# frozen_string_literal: true
class FillProjectSitesHttps < ActiveRecord::Migration
  def change
    # Previous rename was misleading, change to follow conventions:
    rename_column :projects,
                  :project_sites_status,
                  :project_sites_https_status
    rename_column :projects,
                  :project_sites_justification,
                  :project_sites_https_justification
    # Projects with only https URLs already meet 'project_sites_https'
    # Note - you have to execute separate SQL statements *separately*,
    # or the later ones won't be executed.
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE projects SET project_sites_https_status='Met' WHERE
            (repo_url LIKE 'https:%' AND
              (project_homepage_url LIKE 'https:%' OR
               project_homepage_url = '' OR
               project_homepage_url IS NULL));
        SQL
        execute <<-SQL
          UPDATE projects SET project_sites_https_status='Met' WHERE
            (project_homepage_url LIKE 'https:%' AND
              (repo_url LIKE 'https:%' OR
               repo_url = '' OR
               repo_url IS NULL));
        SQL
        execute <<-SQL
          UPDATE projects SET project_sites_https_status='Unmet' WHERE
            ((repo_url LIKE 'http:%') OR (project_homepage_url LIKE 'http:%'));
        SQL
      end
    end
  end
end
