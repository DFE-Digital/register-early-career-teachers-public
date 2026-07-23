module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      include CalculatorPresenters

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      delegate :contract, to: :statement, private: true
    end
  end
end
