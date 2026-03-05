module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

    private

      delegate :number_to_pounds, to: :helpers

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
          <<~TXT.squish
            #{declaration_type_label} (Band
            #{declaration_type_output.band.min_declarations} to
            #{declaration_type_output.band.max_declarations})
          TXT
        when PaymentCalculator::FlatRate
          declaration_type_label
        end
      end

      delegate :contract, to: :statement, private: true

      def calculators
        @calculators ||= PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end
    end
  end
end
