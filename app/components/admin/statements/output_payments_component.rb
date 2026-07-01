module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
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

      def calculators
        @calculators ||= PaymentCalculator::Resolver.new(statement:, contract:)
          .calculators
          .sort_by { it.banded? ? 0 : 1 }
          .map { presenter_for(it) }
      end

      def presenter_for(calculator)
        return ECFPresenter.new(calculator) if contract.ecf_contract_type?
        return FlatRatePresenter.new(calculator) if calculator.flat_rate?
        return BandedPresenter.new(calculator) if calculator.banded?

        raise ArgumentError, "Unknown calculator type: #{calculator.class}"
      end
    end
  end
end
