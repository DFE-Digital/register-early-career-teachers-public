module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      class FlatRatePresenter < BasePresenter
        NON_APPLICABLE_TYPES = %w[retained extended].freeze

        def header = "Mentors"

        def count_for(type)
          return "-" if type.in?(NON_APPLICABLE_TYPES)

          super
        end
      end
    end
  end
end
