class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :delivery_partner, inverse_of: :school_partnerships
  belongs_to :available_provider_pairing, inverse_of: :school_partnerships
  has_many :events

  # Validations
  validates :delivery_partner_id, presence: true
  validates :available_provider_pairing_id, presence: true
end
