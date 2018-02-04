# frozen_string_literal: true

# If you modify this, also modify index.json.builder
json.id project_stat.id
project_stat.attributes.each do |key, value|
  json.set!(key, value) unless value.nil?
end
