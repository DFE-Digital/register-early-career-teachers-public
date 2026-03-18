module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

    private

      def declaration_type_outputs_with_clawbacks(calculator)
        calculator.outputs
          .declaration_type_outputs
          .filter { it.refundable_count.positive? }
      end

      def caption_text(calculator)
        return "Clawbacks" if contract.ecf_contract_type?

        case calculator
        when PaymentCalculator::Banded
          "ECT clawbacks"
        when PaymentCalculator::FlatRate
          "Mentor clawbacks"
        end
      end

      def payment_type(calculator, declaration_type_output)
        declaration_type_label = declaration_type_output.declaration_type.humanize

        case calculator
        when PaymentCalculator::Banded
          "#{declaration_type_label} (Band #{declaration_type_output.band.letter})"
        when PaymentCalculator::FlatRate
          declaration_type_label
        end
      end

      delegate :number_to_pounds, to: :helpers
      delegate :contract, to: :statement, private: true

      def calculators
        @calculators ||= PaymentCalculator::Resolver
          .new(statement:, contract:)
          .calculators
          .sort_by { it.is_a?(PaymentCalculator::Banded) ? 0 : 1 }
      end
    end
  end
end
