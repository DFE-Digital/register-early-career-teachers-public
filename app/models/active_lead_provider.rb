class ActiveLeadProvider < ApplicationRecord
  belongs_to :registration_period, inverse_of: :active_lead_providers
  belongs_to :lead_provider, inverse_of: :active_lead_providers

  validates :registration_period_id,
            presence: { message: 'Choose a registration period' },
            uniqueness: { scope: :lead_provider_id, message: 'Registration period and lead provider must be unique' }

  validates :lead_provider_id, presence: { message: 'Choose a lead provider' }
end
