class DeliveryPartner < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :delivery_partner
  has_many :events
  has_many :lead_provider_delivery_partnerships

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
