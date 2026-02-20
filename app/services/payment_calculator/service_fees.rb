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

    def total
      remaining = banded_fee_structure.recruitment_target

      banded_fee_structure.bands.sum do |band|
        filled = [remaining, band.capacity].min
        remaining -= filled
        filled * band.fee_per_declaration * band.service_fee_ratio
      end
    end
  end
end
