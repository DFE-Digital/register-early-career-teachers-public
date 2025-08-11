module Metadata
  class SchoolContractPeriod < Metadata::Base
    include DeclarativeTouch

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

    touch -> { school }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at
    touch -> { school }, on_event: :update, when_changing: %i[in_partnership induction_programme_choice], timestamp_attribute: :api_updated_at
  end
end
