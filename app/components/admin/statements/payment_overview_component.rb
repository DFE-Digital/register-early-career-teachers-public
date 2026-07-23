module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers
      delegate :contract, to: :statement
      delegate :calculators, to: :statement, private: true
      delegate :banded_calculator, to: :calculators, private: true

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def self.for(statement:)
        raise ArgumentError, "Statement not present" unless statement

        klass =
          if statement.contract.ecf_contract_type?
            PaymentOverview::ECFComponent
          elsif statement.contract.ittecf_ectp_contract_type?
            PaymentOverview::IttecfEctpComponent
          end

        klass.new(statement:)
      end

      def caption
        "Total #{number_to_pounds(total_amount)}"
      end

      def statement_print_link
        govuk_link_to(
          "Save as PDF",
          admin_finance_statement_path(statement),
          no_visited_state: true,
          data: {
            print_link: true,
            print_filename: statement_print_filename
          }
        )
      end

    private

      def statement_print_filename
        "#{statement.lead_provider_name} #{statement.period} financial statement"
      end

      def total_amount
        calculators.sum { |calculator| calculator.total_amount(with_vat: true) }
      end

      def vat_amount
        calculators.sum(&:vat_amount)
      end

      def total_manual_adjustments_amount
        banded_calculator.total_manual_adjustments_amount
      end

      def monthly_service_fee
        banded_calculator.monthly_service_fee
      end

      def outputs
        banded_calculator.outputs.total_billable_amount
      end

      def clawbacks
        -banded_calculator.outputs.total_refundable_amount
      end
    end
  end
end
