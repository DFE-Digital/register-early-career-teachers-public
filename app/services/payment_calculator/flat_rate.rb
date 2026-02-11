module PaymentCalculator
  class FlatRate
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :flat_rate_fee_structure
    attribute :declaration_selector

    def total_amount(with_vat: false)
      if with_vat
        outputs.total_net_amount + vat_amount
      else
        outputs.total_net_amount
      end
    end

    def outputs
      @outputs ||= Outputs.new(declarations: filtered_declarations, fee_per_declaration:)
    end

  private

    def vat_amount = outputs.total_net_amount * vat_rate
    def fee_per_declaration = flat_rate_fee_structure.fee_per_declaration
    def vat_rate = flat_rate_fee_structure.contract.vat_rate

    def filtered_declarations
      declarations = statement.payment_declarations.billable
        .or(statement.clawback_declarations.refundable)
      declaration_selector.call(declarations)
    end
  end
end
