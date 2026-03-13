module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      attr_reader :statement

      delegate :contract, to: :statement, private: true
      delegate :number_to_pounds, to: :helpers

      def initialize(statement:)
        @statement = statement
      end

      def render?
        statement.output_fee?
      end

      def declaration_types(calculator)
        calculator.declaration_type_outputs
          .map(&:declaration_type)
          .uniq
      end

      def outputs_by_type(calculator)
        calculator.outputs.declaration_type_outputs
          .group_by(&:declaration_type)
      end

      def declaration_counts(outputs)
        outputs.map(&:billable_count)
      end

      def declaration_fees(outputs)
        outputs.map(&:type_adjusted_fee_per_declaration)
      end

      def declaration_total(outputs)
        outputs.sum(&:total_billable_amount)
      end

    private

      class BasePresenter < SimpleDelegator
        delegate :total_billable_amount,
                 :declaration_type_outputs,
                 to: :outputs
      end

      class FlatRatePresenter < BasePresenter
        def caption_text = "Mentor output payments"
        def total_label = "Mentors output payment total"
        def fee_label = "Fee per mentor"

        def columns = %w[Participants]
      end

      class BandedPresenter < BasePresenter
        def caption_text = "Early career teacher (ECT) output payments"
        def total_label = "ECTs output payment total"
        def fee_label = "Fee per ECT"

        def columns
          declaration_type_outputs
            .map(&:band)
            .uniq
            .map.with_index { |_, i| "Band " + ("A".ord + i).chr }
        end
      end

      class ECFPresenter < BandedPresenter
        def caption_text = "Output payments"
        def total_label = "Output payment total"
        def fee_label = "Fee per participant"
      end

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
