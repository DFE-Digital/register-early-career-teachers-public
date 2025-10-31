class ActiveLeadProvider < ApplicationRecord
  belongs_to :contract_period, inverse_of: :active_lead_providers, foreign_key: :contract_period_year
  belongs_to :lead_provider, inverse_of: :active_lead_providers
  has_many :lead_provider_delivery_partnerships
  has_many :delivery_partners, through: :lead_provider_delivery_partnerships
  has_many :statements
  has_many :expressions_of_interest, class_name: 'TrainingPeriod', foreign_key: 'expression_of_interest_id', inverse_of: :expression_of_interest
  has_many :events

  validates :contract_period_year,
            presence: { message: 'Choose a contract period' },
            uniqueness: { scope: :lead_provider_id, message: 'Contract period and lead provider must be unique' }
  validates :lead_provider_id, presence: { message: 'Choose a lead provider' }

  scope :for_contract_period, ->(year) { where(contract_period_year: year) }
  scope :for_contract_period_year, ->(contract_period_year) { where(contract_period_year:) }
  scope :excluding_contract_period_year, ->(year) { where.not(contract_period_year: year) }
  scope :for_lead_provider, ->(lead_provider_id) { where(lead_provider_id:) }
  scope :without_existing_partnership_for, ->(delivery_partner, contract_period) {
    where.not(
      id: LeadProviderDeliveryPartnership.active_lead_provider_ids_for(delivery_partner, contract_period)
    )
  }
  scope :with_lead_provider_ordered_by_name, -> { includes(:lead_provider).order('lead_providers.name') }
  scope :available_for_delivery_partner, ->(delivery_partner, contract_period) {
    for_contract_period_year(contract_period.year)
      .without_existing_partnership_for(delivery_partner, contract_period)
      .with_lead_provider_ordered_by_name
  }
end
