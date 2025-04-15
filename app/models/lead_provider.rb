class LeadProvider < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :lead_provider
  has_many :events
  has_many :pending_school_joiners, inverse_of: :lead_provider

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
