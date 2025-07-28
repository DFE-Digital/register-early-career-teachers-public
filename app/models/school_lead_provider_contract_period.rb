class SchoolLeadProviderContractPeriod < ApplicationRecord
  self.primary_key = :school_id, :lead_provider_id, :contract_period_id
  self.table_name = :schools_lead_providers_contract_periods

  enum :training_programme, {
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
  validates :training_programme, inclusion: { in: training_programmes.keys }

  scope :for_lead_provider_contract_period, ->(lead_provider_id, contract_period_id) {
    where(lead_provider_id:,
          contract_period_id:)
  }

  def readonly?
    true
  end
end
