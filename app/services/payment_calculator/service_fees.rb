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

    delegate :recruitment_target, :setup_fee, :band_terms, to: :banded_fee_structure

    # Total service fee = band service fees - setup fee deduction.
    #
    # The setup fee is not charged as a lump sum. Instead it is spread across
    # Band A participants and folded into the monthly payment schedule.
    def total
      band_totals - setup_fee_deduction
    end

    # Sum of (filled participants × per-participant service fee) for each band,
    # filling bands lowest to highest up to the recruitment target.
    def band_totals
      remaining = recruitment_target

      band_terms.sum do |band_term|
        filled = [remaining, band_term.band.capacity].min
        remaining -= filled

        filled * band_term.fee_per_declaration * band_term.service_fee_ratio
      end
    end

    # Deducts setup_fee proportionally based on how many Band A slots are filled.
    # When Band A is fully filled this equals the full setup_fee.
    def setup_fee_deduction
      first_band_allocation_count * setup_fee / first_band_capacity.to_d
    end

    def first_band_allocation_count
      [recruitment_target, first_band_capacity].min
    end

    def first_band_capacity
      band_terms.first.band.capacity
    end
  end
end
