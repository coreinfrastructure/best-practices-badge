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
end
