module Metadata
  class SchoolLeadProviderContractPeriod < Metadata::Base
    self.table_name = :schools_lead_providers_contract_periods_metadata

    enum :induction_programme_choice, {
      not_yet_known: "not_yet_known",
      provider_led: "provider_led",
      school_led: "school_led"
    }

    belongs_to :school
    belongs_to :lead_provider
    belongs_to :contract_period

    validates :school, presence: true
    validates :lead_provider, presence: true
    validates :contract_period, presence: true
    validates :in_partnership, inclusion: { in: [true, false] }
    validates :expression_of_interest, inclusion: { in: [true, false] }
    validates :induction_programme_choice, inclusion: { in: induction_programme_choices.keys }
    validates :school_id, uniqueness: { scope: %i[lead_provider_id contract_period_id] }
  end
end
