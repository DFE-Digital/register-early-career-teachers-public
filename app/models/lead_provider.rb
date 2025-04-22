class LeadProvider < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :lead_provider
  has_many :events
  has_many :active_periods, inverse_of: :lead_provider, class_name: "LeadProviderActivePeriod"

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
