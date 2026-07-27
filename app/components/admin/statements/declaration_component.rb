module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      include CalculatorPresenters

      DECLARATION_TYPES = %w[started retained completed extended].freeze

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

    private

      delegate :contract, to: :statement, private: true

      def declaration_types = DECLARATION_TYPES
    end
  end
end
