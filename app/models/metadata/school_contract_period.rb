module Metadata
  class SchoolContractPeriod < Metadata::Base
    self.table_name = :metadata_schools_contract_periods

    enum :induction_programme_choice, {
      not_yet_known: "not_yet_known",
      provider_led: "provider_led",
      school_led: "school_led"
    }

    belongs_to :school
    belongs_to :contract_period, foreign_key: :contract_period_year

    validates :school, presence: true
    validates :contract_period, presence: true
    validates :in_partnership, inclusion: { in: [true, false] }
    validates :induction_programme_choice, inclusion: { in: induction_programme_choices.keys }
    validates :school_id, uniqueness: { scope: %i[contract_period_year] }
  end
end
