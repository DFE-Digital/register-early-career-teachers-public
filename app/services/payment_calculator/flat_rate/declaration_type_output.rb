module PaymentCalculator
  class FlatRate::DeclarationTypeOutput
    class DeclarationTypeNotSupportedError < StandardError; end
    class FeeProportionsInconsistencyError < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declarations
    attribute :declaration_type
    attribute :fee_per_declaration
    attribute :fee_proportions

    def fee_proportions=(value)
      raise FeeProportionsInconsistencyError, "Fee proportions are inconsistent. Sum of proportions must be 1." if value.values.sum != 1

      super(value)
    end

    def billable_count
      @billable_count ||= declarations_of_matching_type.billable.count
    end

    def refundable_count
      @refundable_count ||= declarations_of_matching_type.refundable.count
    end

    def total_billable_amount
      billable_count * type_adjusted_fee_per_declaration
    end

    def total_refundable_amount
      refundable_count * type_adjusted_fee_per_declaration
    end

    def total_net_amount
      total_billable_amount - total_refundable_amount
    end

  private

    def declarations_of_matching_type
      declarations.where(declaration_type:)
    end

    def type_adjusted_fee_per_declaration
      output_ratio = fee_proportions.fetch(declaration_type.to_sym) do
        raise DeclarationTypeNotSupportedError, "No fee proportion defined for declaration type: #{declaration_type}"
      end
      output_ratio * fee_per_declaration
    end
  end
end
