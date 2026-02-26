module PaymentCalculator
  class Banded::Uplifts
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :billable_declarations
    attribute :refundable_declarations
    attribute :uplift_fee_per_declaration

    def billable_count
      @billable_count ||= with_uplift(billable_declarations).count
    end

    def refundable_count
      @refundable_count ||= with_uplift(refundable_declarations).count
    end

    def net_count
      billable_count - refundable_count
    end

    def total_billable_amount
      billable_count * uplift_fee_per_declaration
    end

    def total_refundable_amount
      refundable_count * uplift_fee_per_declaration
    end

    def total_net_amount
      total_billable_amount - total_refundable_amount
    end

  private

    def with_uplift(declarations)
      declarations
        .where(pupil_premium_uplift: true)
        .or(declarations.where(sparsity_uplift: true))
    end
  end
end
