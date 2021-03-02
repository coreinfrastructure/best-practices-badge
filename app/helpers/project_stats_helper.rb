# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ProjectStatsHelper
  DATE_CHART_OPTIONS = {
    scales:
      {
        xAxes:
        [
          {
            type: 'time',
            unit: 'day',
            unitStepSize: 1,
            ticks: { minRotation: 20 },
            time: {
              # Use these ISO 8601 formats so we're language-neutral
              displayFormats: {
                'day': 'YYYY-MM-DD', 'month': 'YYYY-MM',
                'second': 'HH:MM:ss'
              }
            }
          }
        ]
      }
  }.freeze

  # Create line chart of daily stats from ProjectStat
  # for the provided list of fields
  # rubocop: disable Metrics/MethodLength
  def create_line_chart(fields)
    dataset = []
    fields.each do |field|
      # Add "field" to dataset
      active_dataset =
        ProjectStat.all.reduce({}) do |h, e|
          h.merge(e.created_at => e[field])
        end
      dataset << {
        name: t('.' + field),
        data: active_dataset
      }
    end
    # Done transforming data; return display.
    line_chart dataset, library: DATE_CHART_OPTIONS, defer: true
  end
  # rubocop: enable Metrics/MethodLength
end
