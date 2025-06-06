class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :delivery_partner, inverse_of: :school_partnerships
  belongs_to :available_provider_pairing, inverse_of: :school_partnerships
  has_many :events

  # Validations

  # Scopes
  scope :for_registration_period, ->(year) { where(registration_period_id: year) }
  scope :for_lead_provider, ->(lead_provider_id) { where(lead_provider_id:) }
  scope :for_delivery_partner, ->(delivery_partner_id) { where(delivery_partner_id:) }
  validates :delivery_partner_id, presence: true
  validates :available_provider_pairing_id, presence: true
end
