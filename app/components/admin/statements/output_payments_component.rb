module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      include CalculatorPresenters

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee?
      end

    private

      delegate :number_to_pounds, to: :helpers
      delegate :contract, to: :statement, private: true

      def output_payment_tables
        statement.calculators.map { presenter_for(it) }
      end
    end
  end
end
