module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      include CalculatorPresenters

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

    private

      delegate :contract, to: :statement, private: true

      def clawback_tables
        statement.calculators.map { presenter_for(it) }
      end
    end
  end
end
