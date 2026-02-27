module Admin
  module Statements
    class UpliftFeesComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers

      delegate :net_count,
               :uplift_fee_per_declaration,
               :total_net_amount,
               to: :uplifts

      attr_accessor :statement

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee? && contract.ecf_contract_type?
      end

    private

      delegate :contract, to: :statement

      def calculators
        @calculators ||= PaymentCalculator::Resolver.new(contract:, statement:).calculators
      end

      def uplifts
        raise ArgumentError, "Expected exactly 1 calculator for ECF contract type" unless calculators.one?
        raise ArgumentError, "Expected Banded calculator for ECF contract type" unless calculators.first.is_a?(PaymentCalculator::Banded)

        @uplifts ||= calculators.first.uplifts
      end
    end
  end
end
