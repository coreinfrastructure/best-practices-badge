# frozen_string_literal: true

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
  json.url project_stat_url(project_stat, format: :json)
end
