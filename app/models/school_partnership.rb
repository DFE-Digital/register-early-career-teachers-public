class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :registration_period, inverse_of: :school_partnerships
  belongs_to :lead_provider, inverse_of: :school_partnerships
  belongs_to :delivery_partner, inverse_of: :school_partnerships
  has_many :events

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
end
