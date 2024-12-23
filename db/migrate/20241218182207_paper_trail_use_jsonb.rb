# frozen_string_literal: true

# Change how PaperTrail stores data from YAML (default)
# to JSONB. YAML permits storing of arbitrary datatypes, which is
# actually a bad thing because when Rails changes datatypes it
# creates problems *AND* this flexibility is possibly a security problem
# if we deserialize things incorrectly. Our serialization process is
# trusted, so that shouldn't be a problem, but why not avoid it entirely?
# JSONB is more efficient to store and MUCH more efficient to query.
# The PaperTail "versions" table is now our biggest table, so storing it
# efficiently is a good idea.
#
# We choose the data type jsonb, not data type json.
# Data type jsonb is far more efficient in storage and later retrieval.
# We don't need to record the whitespace, and the key order
# doesn't matter, so the reasons to use data type json don't matter.
#
# We do NOT convert the old data in this migration. The conversion
# takes a long time, and the site does not need go down during
# the conversion. This migration simply ensures that *NEW* data is stored
# in the new format. Once this migration completes, run this:
# > rake convert_papertrail_yaml_to_json
#
# For more information see:
# https://github.com/paper-trail-gem/paper_trail/tree/12-stable

class PaperTrailUseJsonb < ActiveRecord::Migration[7.0]
  def change
    rename_column :versions, :object, :old_yaml_object
    add_column :versions, :object, :jsonb
  end
end
