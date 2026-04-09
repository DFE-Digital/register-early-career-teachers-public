module Metadata
  class SchoolLeadProviderContractPeriod < Metadata::Base
    include DeclarativeUpdates

    self.table_name = :metadata_schools_lead_providers_contract_periods

    belongs_to :school
    belongs_to :lead_provider
    belongs_to :contract_period, foreign_key: :contract_period_year
    has_many :contract_period_metadata, class_name: "Metadata::SchoolContractPeriod", through: :school

    validates :school, presence: true
    validates :lead_provider, presence: true
    validates :contract_period, presence: true
    validates :expression_of_interest_or_school_partnership, inclusion: { in: [true, false] }
    validates :school_id, uniqueness: { scope: %i[lead_provider_id contract_period_year] }

    touch -> { contract_period_metadata }, on_event: :update, when_changing: %i[expression_of_interest_or_school_partnership], timestamp_attribute: :api_updated_at
  end
end
