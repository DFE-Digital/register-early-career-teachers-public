class ActiveLeadProvider < ApplicationRecord
  belongs_to :registration_period, inverse_of: :active_lead_providers
  belongs_to :lead_provider, inverse_of: :active_lead_providers
  has_many :statements

  validates :registration_period_id,
            presence: { message: 'Choose a registration period' },
            uniqueness: { scope: :lead_provider_id, message: 'Registration period and lead provider must be unique' }

  validates :lead_provider_id, presence: { message: 'Choose a lead provider' }

  scope :for_registration_period, ->(year) { where(registration_period_id: year) }
  scope :for_lead_provider, ->(lead_provider_id) { where(lead_provider_id:) }
end
