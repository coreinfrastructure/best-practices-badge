# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

module ProjectStatsHelper
  DATE_CHART_OPTIONS = {
    scales:
      {
        x:
          {
            type: 'time',
            unit: 'day',
            unitStepSize: 1,
            # Setting min & max rotation speeds display. See:
            # https://www.chartjs.org/docs/latest/general/performance.html
            ticks: { minRotation: 30, maxRotation: 30 },
            # Set time format (changed from older chartkick). See:
            # https://www.chartjs.org/docs/latest/axes/cartesian/time.html
            # and https://git.io/fxCyr
            time: {
              # Use these ISO 8601 formats so we're language-neutral
              displayFormats: {
                day: 'yyyy-MM-dd', month: 'yyyy-MM',
                second: 'HH:MM:ss'
              }
            }
          }
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
