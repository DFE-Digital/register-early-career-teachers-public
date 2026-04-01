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
        @calculators ||= PaymentCalculator::Resolver.new(statement:, contract:).calculators
          .sort_by { |c| c.is_a?(PaymentCalculator::Banded) ? 0 : 1 }
          .map { presenter_for it }
      end

      def presenter_for(calculator)
        if contract.ecf_contract_type?
          ECFPresenter.new(calculator)
        elsif calculator.is_a?(PaymentCalculator::FlatRate)
          FlatRatePresenter.new(calculator)
        elsif calculator.is_a?(PaymentCalculator::Banded)
          BandedPresenter.new(calculator)
        else
          raise ArgumentError, "Unknown calculator type: #{calculator.class}"
        end
      end
    end
  end
end
