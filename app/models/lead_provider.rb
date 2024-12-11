class LeadProvider < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :lead_provider
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
