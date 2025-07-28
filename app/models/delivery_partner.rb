class DeliveryPartner < ApplicationRecord
  include DeclarativeTouch

  # Associations
  has_many :lead_provider_delivery_partnerships, inverse_of: :delivery_partner
  has_many :school_partnerships, through: :lead_provider_delivery_partnerships
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true
  validates :api_id, uniqueness: { case_sensitive: false, message: "API id already exists for another delivery partner" }

  touch -> { self }, when_changing: %i[name], timestamp_attribute: :api_updated_at
end
