module PaymentCalculator
  class ServiceFees
    include ActiveModel::Model
    include ActiveModel::Attributes

    NUMBER_OF_PAYMENTS = 29

    attribute :banded_fee_structure

    def monthly_amount
      total / NUMBER_OF_PAYMENTS
    end

  private

    delegate :recruitment_target, :setup_fee, :terms, to: :banded_fee_structure

    # Total service fee = band service fees - setup fee deduction.
    #
    # The setup fee is not charged as a lump sum. Instead it is spread across
    # Band A participants and folded into the monthly payment schedule.
    def total
      term_totals - setup_fee_deduction
    end

    # Sum of (filled participants × per-participant service fee) for each band,
    # filling bands lowest to highest up to the recruitment target.
    def term_totals
      remaining = recruitment_target

      terms.sum do |term|
        filled = [remaining, term.capacity].min
        remaining -= filled

        filled * term.fee_per_declaration * term.service_fee_ratio
      end
    end

    # Deducts setup_fee proportionally based on how many Band A slots are filled.
    # When Band A is fully filled this equals the full setup_fee.
    def setup_fee_deduction
      filled_in_first_term * setup_fee / first_term_capacity.to_d
    end

    def filled_in_first_term
      [recruitment_target, first_term_capacity].min
    end

    def first_term_capacity
      terms.first.capacity
    end
  end
end
