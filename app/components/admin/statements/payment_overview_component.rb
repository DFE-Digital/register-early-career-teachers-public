module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def rows
        [
          ["Output payment", { text: number_to_pounds(outputs), numeric: true }],
          ["Service fee", { text: number_to_pounds(monthly_service_fee), numeric: true }],
          ["Uplift fees", { text: number_to_pounds(uplifts), numeric: true }],
          ["Clawbacks", { text: number_to_pounds(clawbacks), numeric: true }],
          ["Additional adjustments", { text: number_to_pounds(total_manual_adjustments_amount), numeric: true }],
          ["VAT", { text: number_to_pounds(vat_amount), numeric: true }],
        ]
      end

      # Common Elements
      def total_payment_text
        number_to_pounds(total_amount)
      end

      def formatted_deadline_date
        statement.deadline_date.to_fs(:govuk)
      end

      def formatted_payment_date
        statement.payment_date.to_fs(:govuk)
      end

      # private

      delegate :contract, to: :statement

      def calculator
        @calculator ||= pre_2025? ? calculators.first : calculators.second
      end

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def pre_2025?
        contract.contract_type == "ecf"
      end

      def total_amount
        @total_amount ||= calculator.total_amount(with_vat: true)
      end

      def vat_amount
        @vat_amount ||= calculator.vat_amount
      end

      def total_manual_adjustments_amount
        @total_manual_adjustments_amount ||= calculator.total_manual_adjustments_amount
      end

      def monthly_service_fee
        @monthly_service_fee ||= calculator&.monthly_service_fee
      end

      # PRE 2025
      def outputs
        @outputs ||= calculator.outputs.total_net_amount
      end

      def clawbacks
        0.0
      end

      def uplifts
        @uplifts ||= calculator.uplifts.total_net_amount
      end

      # POST 2025
      def ects_output_payment
      end

      def mentors_output_payment
      end

      def ects_clawbacks
      end

      def mentors_clawbacks
      end
    end
  end
end
