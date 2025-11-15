# frozen_string_literal: true

# Copyright 2020-, the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Controller for criteria functionality.
#
class CriteriaController < ApplicationController
  # Displays list of resources.
  # @return [void]
  def index
    set_params
  end

  # Displays individual resource details.
  # @return [void]
  def show
    set_criteria_level
    set_params
  end

  private

  # Sets criteria_level value.
  # @return [void]
  def set_criteria_level
    level_param = params[:criteria_level] || '0'
    @criteria_level = normalize_criteria_level(level_param)
  end

  # Convert criteria level URL parameter to internal format (YAML key format)
  # Accepts: '0', '1', '2', 'passing', 'bronze', 'silver', 'gold'
  # Returns: '0', '1', or '2' (defaults to '0')
  # rubocop:disable Lint/DuplicateBranch
  def normalize_criteria_level(level)
    case level.to_s.downcase
    when '0', 'passing', 'bronze' then '0'
    when '1', 'silver' then '1'
    when '2', 'gold' then '2'
    else '0' # Default fallback
    end
  end
  # rubocop:enable Lint/DuplicateBranch

  # Set user-provided parameters (other than criteria_level)
  def set_params
    @details = boolean_param(:details, false)
    @rationale = boolean_param(:rationale, false)
    @autofill = boolean_param(:autofill, false)
  end

  # Convert user-provided parameter "name" into true/false.
  # This is untrusted input, be cautious with it.
  # @param name [String] The name name
  # @param default_value [Object] The default value parameter
  # @return [Boolean]
  def boolean_param(name, default_value = true)
    if params.key?(name)
      user_value = params[name]
      user_value.casecmp?('true') || user_value == '1'
    else
      default_value
    end
  end
end
