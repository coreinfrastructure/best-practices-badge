# frozen_string_literal: true

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
