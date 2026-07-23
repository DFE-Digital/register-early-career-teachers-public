module Admin
  module Statements
    class UpliftFeesComponent < ApplicationComponent
      delegate :billable_count,
               :uplift_fee_per_declaration,
               :total_billable_amount,
               to: :uplifts

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee? && contract.ecf_contract_type?
      end

    private

      delegate :contract, :calculators, to: :statement, private: true

      def uplifts
        @uplifts ||= calculators.banded_calculator.uplifts
      end
    end
  end
end
