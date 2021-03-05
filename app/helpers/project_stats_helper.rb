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
            # Setting min & max rotation speeds diplay. See:
            # https://www.chartjs.org/docs/latest/general/performance.html
            ticks: { minRotation: 30, maxRotation: 30 },
            time: {
              # Use these ISO 8601 formats so we're language-neutral
              displayFormats: {
                'day': 'YYYY-MM-DD', 'month': 'YYYY-MM',
                'second': 'HH:MM:ss'
              }
            }
          }
        ]
      },
    elements:
      {
        # Disable bezier curves because simple lines are faster. See:
        # https://www.chartjs.org/docs/latest/general/performance.html
        line:
          {
                tension: 0
          }
      }
  }.freeze
end
