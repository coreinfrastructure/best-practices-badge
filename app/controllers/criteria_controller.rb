# frozen_string_literal: true

# Copyright 2020-, the Linux Foundation and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

class CriteriaController < ApplicationController
  def index; end

  def show
    set_criteria_level
  end

  private

  def set_criteria_level
    @criteria_level = params[:criteria_level] || '0'
    @criteria_level = '0' unless @criteria_level.match?(/\A[0-2]\Z/)
  end
end
