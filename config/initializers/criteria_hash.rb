require 'yaml'
CriteriaHash = YAML.load(File.open('criteria.yml')).with_indifferent_access
                   .freeze
# binding.pry
Test.instantiate
