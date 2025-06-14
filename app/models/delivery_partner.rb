class DeliveryPartner < ApplicationRecord
  # Associations
  has_many :lead_provider_delivery_partnerships, inverse_of: :delivery_partner
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
