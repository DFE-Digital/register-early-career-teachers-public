module Admin
  module Statements
    class UpliftFeesComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers

      delegate :billable_count,
               :uplift_fee_per_declaration,
               :total_billable_amount,
               to: :uplifts

      attr_accessor :statement

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee? && contract.ecf_contract_type?
      end

    private

      delegate :contract, :calculators, to: :statement

      def uplifts
        @uplifts ||= calculators.banded_calculator.uplifts
      end
    end
  end
end
