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
    @criteria_level = params[:criteria_level] || '0'
    @criteria_level = '0' unless @criteria_level.match?(/\A[0-2]\Z/)
  end

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
