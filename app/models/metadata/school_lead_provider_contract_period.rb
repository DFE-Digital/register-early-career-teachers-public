module Metadata
  class SchoolLeadProviderContractPeriod < Metadata::Base
    self.table_name = :metadata_schools_lead_providers_contract_periods

    belongs_to :school
    belongs_to :lead_provider
    belongs_to :contract_period, foreign_key: :contract_period_year

    validates :school, presence: true
    validates :lead_provider, presence: true
    validates :contract_period, presence: true
    validates :expression_of_interest, inclusion: { in: [true, false] }
    validates :school_id, uniqueness: { scope: %i[lead_provider_id contract_period_year] }
  end
end
