class CriteriaController < ApplicationController
  def index
  end

  def show
    set_criteria_level
  end

  def set_criteria_level
    @criteria_level = params[:criteria_level] || '0'
    @criteria_level = '0' unless @criteria_level.match?(/\A[0-2]\Z/)
  end
end
