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

      delegate :contract, to: :statement, private: true
    end
  end
end
