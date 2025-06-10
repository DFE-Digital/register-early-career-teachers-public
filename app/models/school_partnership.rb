class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  has_many :events

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
end
