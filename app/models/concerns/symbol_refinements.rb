# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

module SymbolRefinements
  refine Symbol do
    def status
      "#{self}_status".to_sym
    end

    def justification
      "#{self}_justification".to_sym
    end
  end
end
