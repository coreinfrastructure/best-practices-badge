# frozen_string_literal: true
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
