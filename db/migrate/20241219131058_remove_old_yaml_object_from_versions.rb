# frozen_string_literal: true

# Remove old_yaml_object. We now store version information in the
# column "object" in JSON format and we have converted all the data in
# YAML format to the JSON format. We *could* retain the YAML copy,
# but it takes up a lot of space for no gain.

class RemoveOldYamlObjectFromVersions < ActiveRecord::Migration[7.1]
  def change
    remove_column :versions, :old_yaml_object, :text
  end
end
