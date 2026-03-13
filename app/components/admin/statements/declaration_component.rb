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

        case calculator
        when PaymentCalculator::Banded
          "ECTs"
        when PaymentCalculator::FlatRate
          "Mentors"
        end
      end

    private

      def ecf_contract?
        contract.ecf_contract_type?
      end

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def ordered_calculators
        case contract.contract_type
        when "ecf"
          raise ArgumentError, "Expected one banded calculator for ECF contract type" unless calculators.one? && banded_calculator

          [banded_calculator]
        when "ittecf_ectp"
          raise ArgumentError, "Expected banded and flat rate calculator for ITTECF ECTP contract type" unless flat_rate_calculator && banded_calculator

          [banded_calculator, flat_rate_calculator]
        else
          raise ArgumentError
        end
      end

      def banded_calculator
        calculators.find { it.is_a? PaymentCalculator::Banded }
      end

      def flat_rate_calculator
        calculators.find { it.is_a? PaymentCalculator::FlatRate }
      end

      def declarations_count(calculator, type)
        calculator.outputs.declaration_type_outputs
          .select { it.declaration_type.start_with?(type) }
          .sum(&:billable_count)
      end

      def refunded(calculator)
        calculator.outputs.total_refundable_count
      end

      def voided(calculator)
        calculator.voided_declarations_count
      end
    end
  end
end
