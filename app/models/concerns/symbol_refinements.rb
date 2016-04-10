# frozen_string_literal: true
module SymbolRefinements
  refine Symbol do
    def status
      @status ||= "#{self}_status".to_sym
    end

    def justification
      @justification ||= "#{self}_justification".to_sym
    end
  end
end
