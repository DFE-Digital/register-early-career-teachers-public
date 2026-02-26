module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers
      delegate :contract, to: :statement

      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def rows
        rows = [
          [output_payment_text, { text: number_to_pounds(outputs), numeric: true }],

        ]

        rows << ["Mentors output payment", { text: number_to_pounds(mentors_outputs), numeric: true }] unless ecf_contract?
        rows << ["Service fee", { text: number_to_pounds(monthly_service_fee), numeric: true }]
        rows << ["Uplift fees", { text: number_to_pounds(uplifts), numeric: true }] if ecf_contract?
        rows << [clawback_payment_text, { text: number_to_pounds(clawbacks), numeric: true }]
        rows << ["Mentors clawbacks", { text: number_to_pounds(mentors_clawbacks), numeric: true }] unless ecf_contract?
        rows << ["Additional adjustments", { text: number_to_pounds(total_manual_adjustments_amount), numeric: true }]
        rows << ["VAT", { text: number_to_pounds(vat_amount), numeric: true }]

        rows
      end

      def caption
        number_to_pounds(total_amount)
      end

      def formatted_deadline_date
        statement.deadline_date.to_fs(:govuk)
      end

      def formatted_payment_date
        statement.payment_date.to_fs(:govuk)
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def banded
        @banded ||= calculators.last
      end

      def flat_rate
        @flat_rate ||= calculators.first
      end

      def ecf_contract?
        contract.contract_type == "ecf"
      end

      def total_amount
        ecf_contract? ? banded_total : banded_total + flat_rate_total
      end

      def banded_total
        @banded_total ||= banded.total_amount(with_vat: true)
      end

      def flat_rate_total
        @flat_rate_total ||= flat_rate.total_amount(with_vat: true)
      end

      def vat_amount
        ecf_contract? ? banded_vat : banded_vat + flat_rate_vat
      end

      def banded_vat
        @banded_vat_amount ||= banded.vat_amount
      end

      def flat_rate_vat
        @flat_rate_vat_amount ||= flat_rate.vat_amount
      end

      def total_manual_adjustments_amount
        @total_manual_adjustments_amount ||= banded.total_manual_adjustments_amount
      end

      def monthly_service_fee
        @monthly_service_fee ||= banded.monthly_service_fee
      end

      def outputs
        @outputs ||= banded.outputs.total_net_amount
      end

      def mentors_outputs
        @mentors_outputs ||= flat_rate.outputs.total_net_amount
      end

      def clawbacks
        @clawbacks ||= banded.outputs.total_refundable_amount
      end

      def mentors_clawbacks
        @mentors_clawbacks ||= flat_rate.outputs.total_refundable_amount
      end

      def uplifts
        @uplifts ||= banded.uplifts.total_net_amount
      end

      def output_payment_text
        ecf_contract? ? "Output payment" : "ECTs output payment"
      end

      def clawback_payment_text
        ecf_contract? ? "Clawbacks" : "ECTs clawbacks"
      end
    end
  end
end
