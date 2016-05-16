# frozen_string_literal: true
class AddStatsExtension < ActiveRecord::Migration
  def change
    enable_extension 'pg_stat_statements'
  end
end
