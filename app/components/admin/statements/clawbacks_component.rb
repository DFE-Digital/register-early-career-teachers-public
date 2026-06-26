module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

    private

      Row = Data.define(:payment_type, :refundable_count, :fee_per_declaration, :total_refundable_amount)

      def rows(calculator)
        rows = calculator.outputs
          .declaration_type_outputs
          .filter { it.refundable_count.positive? }
          .map do |output|
            Row.new(
              payment_type: payment_type(calculator, output),
              refundable_count: output.refundable_count,
              fee_per_declaration: output.type_adjusted_fee_per_declaration,
              total_refundable_amount: output.total_refundable_amount
            )
          end

        rows << uplift_row(calculator) if include_uplift?(calculator)
        rows
      end

      def total(calculator)
        total = calculator.outputs.total_refundable_amount
        total += calculator.uplifts.total_refundable_amount if include_uplift?(calculator)
        total
      end

      def include_uplift?(calculator)
        contract.ecf_contract_type? &&
          calculator.is_a?(PaymentCalculator::Banded) &&
          calculator.uplifts.refundable_count.positive?
      end

      def uplift_row(calculator)
        Row.new(
          payment_type: "Uplift",
          refundable_count: calculator.uplifts.refundable_count,
          fee_per_declaration: calculator.uplifts.uplift_fee_per_declaration,
          total_refundable_amount: calculator.uplifts.total_refundable_amount
        )
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
          "#{declaration_type_label} (Band #{declaration_type_output.band_term.band.letter})"
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
