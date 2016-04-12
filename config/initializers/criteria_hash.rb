require 'yaml'
CriteriaHash = YAML.load(File.open('criteria.yml')).with_indifferent_access
                   .freeze
Criteria.instantiate
