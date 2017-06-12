# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module StringRefinements
  refine String do
    def met?
      self == 'Met'
    end

    def na?
      self == 'N/A'
    end

    def unknown?
      self == '?'
    end

    def unmet?
      self == 'Unmet'
    end
  end
end
