module PaymentCalculator
  class FlatRate
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :flat_rate_fee_structure
    attribute :declaration_selector
    attribute :fee_proportions

    def total_amount(with_vat: false)
      if with_vat
        outputs.total_net_amount + vat_amount
      else
        outputs.total_net_amount
      end
    end

    def vat_amount = outputs.total_net_amount * vat_rate

    def outputs
      @outputs ||= FlatRate::Outputs.new(
        billable_declarations: filtered_billable_declarations,
        refundable_declarations: filtered_refundable_declarations,
        fee_per_declaration:,
        fee_proportions:
      )
    end

    def voided_declarations_count
      filtered_voided_declarations.count
    end

  private

    def fee_per_declaration = flat_rate_fee_structure.fee_per_declaration
    def vat_rate = flat_rate_fee_structure.contract.applicable_vat_rate

    def filtered_billable_declarations
      declaration_selector.call(statement.payment_declarations.billable)
    end

    def filtered_refundable_declarations
      declaration_selector.call(statement.clawback_declarations.refundable)
    end

    def filtered_voided_declarations
      declarations = statement.payment_declarations.payment_status_voided

      declaration_selector.call(declarations)
    end
  end
end
