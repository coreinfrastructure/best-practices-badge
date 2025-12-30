# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module StringRefinements
  refine String do
    def met?
      self == 'Met' || self == '3' # Phase 2: handle stringified integer
    end

    def na?
      self == 'N/A' || self == '2' # Phase 2: handle stringified integer
    end

    def unknown?
      self == '?' || self == '0' # Phase 2: handle stringified integer
    end

    def unmet?
      self == 'Unmet' || self == '1' # Phase 2: handle stringified integer
    end
  end
end
