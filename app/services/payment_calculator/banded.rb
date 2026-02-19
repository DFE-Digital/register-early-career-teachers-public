module PaymentCalculator
  class Banded
    include ActiveModel::Model
    include ActiveModel::Attributes

    NUMBER_OF_SERVICE_FEE_PAYMENTS = 29

    attribute :statement
    attribute :banded_fee_structure
    attribute :declaration_selector

    def outputs
      @outputs ||= Banded::Outputs.new(
        declarations: filtered_declarations,
        previous_declarations: filtered_previous_declarations,
        banded_fee_structure:
      )
    end

    def uplifts
      @uplifts ||= Banded::Uplifts.new(
        declarations: filtered_declarations,
        uplift_fee_per_declaration:
      )
    end

    def monthly_service_fee
      banded_fee_structure.monthly_service_fee || calculated_monthly_service_fee
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

  private

    def subtotal
      @subtotal ||= outputs.total_net_amount +
        uplifts.total_net_amount +
        monthly_service_fee +
        setup_fee +
        total_manual_adjustments_amount
    end

    def vat_amount
      subtotal * vat_rate
    end

    def declarations
      statement.payment_declarations.billable.or(statement.clawback_declarations.refundable)
    end

    def previous_declarations
      Declaration.where(payment_statement: previous_statements).billable
        .or(Declaration.where(clawback_statement: previous_statements).refundable)
    end

    def filtered_declarations
      @filtered_declarations ||= declaration_selector.call(declarations)
    end

    def filtered_previous_declarations
      @filtered_previous_declarations ||= declaration_selector.call(previous_declarations)
    end

    def previous_statements
      Statement
        .where(active_lead_provider: statement.active_lead_provider)
        .where(payment_date: ...statement.payment_date)
    end

    def calculated_monthly_service_fee
      remaining = banded_fee_structure.recruitment_target

      total = banded_fee_structure.bands.sum do |band|
        capacity = band.max_declarations - band.min_declarations + 1
        filled = [remaining, capacity].min
        remaining -= filled
        filled * band.fee_per_declaration * band.service_fee_ratio
      end

      total / NUMBER_OF_SERVICE_FEE_PAYMENTS
    end

    def uplift_fee_per_declaration
      banded_fee_structure.uplift_fee_per_declaration
    end

    def vat_rate
      statement.contract.vat_rate
    end
  end
end
