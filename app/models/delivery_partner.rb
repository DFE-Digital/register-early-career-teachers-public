class DeliveryPartner < ApplicationRecord
  # Associations
  has_many :provider_partnerships, inverse_of: :delivery_partner
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
end
