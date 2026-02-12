module Migration
  class ParticipantBand < Migration::Base
    belongs_to :call_off_contract

    scope :min_nulls_first, -> { order("min asc nulls first") }

    def attributes
      super.merge(
        "min_declarations" => [(min || 1), 1].max, # ECF uses nil/0 but we default to 1 in RECT
        "max_declarations" => max,
        "fee_per_declaration" => per_participant,
        "output_fee_ratio" => (output_payment_percentage / 100.0).to_d,
        "service_fee_ratio" => (service_fee_percentage / 100.0).to_d
      )
    end
  end
end
