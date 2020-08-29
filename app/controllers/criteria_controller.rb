# frozen_string_literal: true

# Copyright 2020-, the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class CriteriaController < ApplicationController
  def index
    set_params
  end

  def show
    set_criteria_level
    set_params
  end

  private

  def set_criteria_level
    @criteria_level = params[:criteria_level] || '0'
    @criteria_level = '0' unless @criteria_level.match?(/\A[0-2]\Z/)
  end

  # Set user-provided parameters (other than criteria_level)
  def set_params
    @details = boolean_param(:details)
    @rationale = boolean_param(:rationale)
  end

  # Convert user-provided parameter "name" into true/false.
  # This is untrusted input, be cautious with it.
  def boolean_param(name, default_value = true)
    if params.key?(name)
      user_value = params[name]
      user_value.casecmp?('true') or user_value == '1'
    else
      default_value
    end
  end
end
