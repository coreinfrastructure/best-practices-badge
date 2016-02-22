require 'yaml'
Criteria = YAML.load(File.open('criteria.yml')).with_indifferent_access.freeze
