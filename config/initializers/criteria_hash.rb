# frozen_string_literal: true
require 'yaml'
CriteriaHash = YAML.load_file('criteria.yml').with_indifferent_access.freeze
