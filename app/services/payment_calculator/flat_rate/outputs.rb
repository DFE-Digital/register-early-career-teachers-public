module PaymentCalculator
  module FlatRate
    class Outputs
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :declarations
      attribute :fee_per_declaration

      def declaration_type_outputs
        @declaration_type_outputs ||= Declaration.declaration_types.keys.map do |declaration_type|
          DeclarationTypeOutput.new(declarations:, declaration_type:, fee_per_declaration:)
        end
      end

      def total_billable_amount
        @total_billable_amount ||= declaration_type_outputs.sum(&:total_billable_amount)
      end

      def total_refundable_amount
        @total_refundable_amount ||= declaration_type_outputs.sum(&:total_refundable_amount)
      end

      def total_net_amount
        @total_net_amount ||= declaration_type_outputs.sum(&:total_net_amount)
      end
    end
  end
end
