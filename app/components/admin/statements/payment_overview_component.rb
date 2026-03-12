module Admin
  module Statements
    class PaymentOverviewComponent < ApplicationComponent
      delegate :number_to_pounds, to: :helpers
      delegate :contract, to: :statement

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

      def total
        number_to_pounds(total_amount)
      end

    private

      def total_amount
        calculators.sum { |calculator| calculator.total_amount(with_vat: true) }
      end

      def vat_amount
        calculators.sum(&:vat_amount)
      end

      def calculators
        @calculators ||= PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def banded
        @banded ||= calculators.find { |c| c.is_a? PaymentCalculator::Banded }
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

      def clawbacks
        @clawbacks ||= banded.outputs.total_refundable_amount
      end
    end
  end
end
