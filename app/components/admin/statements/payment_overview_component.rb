module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      delegate :contract, to: :statement
      delegate :calculators, to: :statement, private: true
      delegate :banded_calculator, to: :calculators, private: true
      delegate :monthly_service_fee, :total_manual_adjustments_amount, to: :banded_calculator, private: true
      delegate :outputs, to: :banded_calculator, private: true

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

      def total_amount = calculators.sum { it.total_amount(with_vat: true) }

      def vat_amount = calculators.sum(&:vat_amount)

      def output_payment = outputs.total_billable_amount

      def clawbacks = -outputs.total_refundable_amount
    end
  end
end
