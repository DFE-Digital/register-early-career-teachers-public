module PaymentCalculator
  class FlatRate::DeclarationTypeOutput
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declarations
    attribute :declaration_type
    attribute :fee_per_declaration
    attribute :fee_proportions

    def billable_count
      @billable_count ||= declarations_of_matching_type.billable.count
    end

    def refundable_count
      @refundable_count ||= declarations_of_matching_type.refundable.count
    end

    def total_billable_amount
      billable_count * total_fee_per_declaration
    end

    def total_refundable_amount
      refundable_count * total_fee_per_declaration
    end

    def total_net_amount
      total_billable_amount - total_refundable_amount
    end

  private

    def declarations_of_matching_type
      declarations.where(declaration_type:)
    end

    def total_fee_per_declaration
      output_ratio = fee_proportions[declaration_type.to_sym] || 0
      output_ratio * fee_per_declaration
    end
  end
end
