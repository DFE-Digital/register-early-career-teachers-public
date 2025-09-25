module Metadata
  class SchoolLeadProviderContractPeriod < Metadata::Base
    include DeclarativeUpdates

    self.table_name = :metadata_schools_lead_providers_contract_periods

    belongs_to :school
    belongs_to :lead_provider
    belongs_to :contract_period, foreign_key: :contract_period_year

    validates :school, presence: true
    validates :lead_provider, presence: true
    validates :contract_period, presence: true
    validates :expression_of_interest, inclusion: { in: [true, false] }
    validates :school_id, uniqueness: { scope: %i[lead_provider_id contract_period_year] }

    touch -> { school }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at
    touch -> { school }, on_event: :update, when_changing: %i[expression_of_interest], timestamp_attribute: :api_updated_at
  end
end
