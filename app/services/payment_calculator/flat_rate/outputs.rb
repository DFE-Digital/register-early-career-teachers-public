module PaymentCalculator
  class FlatRate::Outputs
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declarations
    attribute :fee_per_declaration
    attribute :fee_proportions

    def declaration_type_outputs
      @declaration_type_outputs ||= declaration_types.map do |declaration_type|
        FlatRate::DeclarationTypeOutput.new(declarations:, declaration_type:, fee_per_declaration:, fee_proportions:)
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

  private

    def declaration_types
      declarations.pluck("DISTINCT declaration_type")
    end
  end
end
