class LeadProvider < ApplicationRecord
  # Associations
  has_many :active_periods, inverse_of: :lead_provider, class_name: "LeadProviderActivePeriod"
  has_many :school_partnerships, inverse_of: :lead_provider
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
