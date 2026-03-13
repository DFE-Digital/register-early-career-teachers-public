module PaymentCalculator
  class Banded
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :banded_fee_structure
    attribute :declaration_selector

    def outputs
      @outputs ||= Banded::Outputs.new(
        billable_declarations: filtered_billable_declarations,
        refundable_declarations: filtered_refundable_declarations,
        previous_billable_declarations: filtered_previous_billable_declarations,
        previous_refundable_declarations: filtered_previous_refundable_declarations,
        banded_fee_structure:
      )
    end

    def uplifts
      @uplifts ||= Banded::Uplifts.new(
        billable_declarations: filtered_billable_declarations,
        refundable_declarations: filtered_refundable_declarations,
        uplift_fee_per_declaration:
      )
    end

    def monthly_service_fee
      banded_fee_structure.monthly_service_fee || service_fees.monthly_amount
    end

    delegate :setup_fee, to: :banded_fee_structure

    def total_manual_adjustments_amount
      statement.adjustments.sum(:amount)
    end

    def total_amount(with_vat: false)
      if with_vat
        subtotal + vat_amount
      else
        subtotal
      end
    end

    def vat_amount = subtotal * vat_rate

    def voided_declarations_count
      filtered_voided_declarations.count
    end

  private

    def subtotal
      @subtotal ||= outputs.total_net_amount +
        uplifts.total_net_amount +
        monthly_service_fee +
        total_manual_adjustments_amount
    end

    def billable_declarations
      Declaration.where(payment_statement: statement).billable
    end

    def refundable_declarations
      Declaration.where(clawback_statement: statement).refundable
    end

    def previous_billable_declarations
      Declaration.where(payment_statement: previous_statements).billable
    end

    def previous_refundable_declarations
      Declaration.where(clawback_statement: previous_statements).refundable
    end

    def voided_declarations
      Declaration.where(payment_statement: statement).payment_status_voided
    end

    def filtered_billable_declarations
      @filtered_billable_declarations ||= declaration_selector.call(billable_declarations)
    end

    def filtered_refundable_declarations
      @filtered_refundable_declarations ||= declaration_selector.call(refundable_declarations)
    end

    def filtered_previous_billable_declarations
      @filtered_previous_billable_declarations ||= declaration_selector.call(previous_billable_declarations)
    end

    def filtered_previous_refundable_declarations
      @filtered_previous_refundable_declarations ||= declaration_selector.call(previous_refundable_declarations)
    end

    def filtered_voided_declarations
      @filtered_voided_declarations ||= declaration_selector.call(voided_declarations)
    end

    def previous_statements
      Statement.joins(:contract)
        .where(contracts: { active_lead_provider_id: statement.active_lead_provider.id })
        .where(payment_date: ...statement.payment_date)
    end

    def service_fees
      @service_fees ||= PaymentCalculator::ServiceFees.new(banded_fee_structure:)
    end

    def uplift_fee_per_declaration
      banded_fee_structure.uplift_fee_per_declaration
    end

    def vat_rate
      statement.contract.vat_rate
    end
  end
end
