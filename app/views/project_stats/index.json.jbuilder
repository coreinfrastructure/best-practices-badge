# frozen_string_literal: true

# If you modify this, also modify show.json.builder
# We intentionally are non-DRY, and duplicate parts of these two files
# for speed (in normal use people use "index" with a loop-in-loop).
# It is also fairly unlikely that these files will be changed, because
# they automatically include whatever fields are available.

json.array!(@project_stats) do |project_stat|
  # Force "id" to be first
  json.id project_stat.id
  # Include all the attributes of project_stat (if more are added, they
  # are automatically included here).
  # We cannot use "json.merge! project_stat.attributes" because that
  # ignores the "json.ignore_nil!" setting.  Instead, do the loop by hand:
  project_stat.attributes.each do |key, value|
    json.set!(key, value) unless value.nil?
  end
  # Historically we included a per-stat URL, but we'd like to drop
  # that functionality so we won't include that URL
end
