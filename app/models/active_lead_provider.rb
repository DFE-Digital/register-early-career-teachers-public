class ActiveLeadProvider < ApplicationRecord
  belongs_to :contract_period, inverse_of: :active_lead_providers
  belongs_to :lead_provider, inverse_of: :active_lead_providers
  has_many :lead_provider_delivery_partnerships
  has_many :delivery_partners, through: :lead_provider_delivery_partnerships
  has_many :statements
  has_many :expressions_of_interest, class_name: 'TrainingPeriod', foreign_key: 'expression_of_interest_id', inverse_of: :expression_of_interest
  has_many :events

  validates :contract_period_id,
            presence: { message: 'Choose a contract period' },
            uniqueness: { scope: :lead_provider_id, message: 'Contract period and lead provider must be unique' }

  validates :lead_provider_id, presence: { message: 'Choose a lead provider' }

  scope :for_contract_period, ->(year) { where(contract_period_id: year) }
  scope :for_lead_provider, ->(lead_provider_id) { where(lead_provider_id:) }
end
