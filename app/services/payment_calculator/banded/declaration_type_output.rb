module PaymentCalculator
  module Banded
    class DeclarationTypeOutput
      class DeclarationTypeNotSupportedError < StandardError; end

      include ActiveModel::Model
      include ActiveModel::Attributes

      FEE_PROPORTIONS = {
        "started" => 0.2,
        "completed" => 0.2,
        "retained-1" => 0.15,
        "retained-2" => 0.15,
        "retained-3" => 0.15,
        "retained-4" => 0.15,
        "extended-1" => 0.15,
        "extended-2" => 0.15,
        "extended-3" => 0.15,
      }.freeze

      attribute :band_allocation

      delegate :declaration_type, to: :band_allocation

      def output_fee_per_declaration
        fee_proportion * band.output_fee_ratio * band.fee_per_declaration
      end

      def total_billable_amount = billable_count * output_fee_per_declaration
      def total_refundable_amount = refundable_count * output_fee_per_declaration
      def total_net_amount = total_billable_amount - total_refundable_amount

    private

      def fee_proportion
        FEE_PROPORTIONS.fetch(declaration_type) do
          raise DeclarationTypeNotSupportedError,
                "No fee proportion defined for declaration type: #{declaration_type}"
        end
      end

      delegate :billable_count, :refundable_count, :band,
               to: :band_allocation,
               private: true
    end
  end
end
