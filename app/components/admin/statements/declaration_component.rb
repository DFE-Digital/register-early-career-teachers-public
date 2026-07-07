module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      attr_accessor :statement

      delegate :contract, to: :statement

      def initialize(statement:)
        @statement = statement
      end

      def count_header_text(calculator)
        return "Total" if ecf_contract?
        return "ECTs" if calculator.banded?

        "Mentors"
      end

    private

      def ecf_contract?
        contract.ecf_contract_type?
      end

      delegate :calculators, to: :statement, private: true

      def declarations_count(calculator, type)
        calculator.outputs.declaration_type_outputs
          .select { it.declaration_type.start_with?(type) }
          .sum(&:billable_count)
      end

      def refunded_count(calculator)
        calculator.outputs.total_refundable_count
      end

      def voided_count(calculator)
        calculator.voided_declarations_count
      end
    end
  end
end
