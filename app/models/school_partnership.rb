class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :registration_period, inverse_of: :school_partnerships
  belongs_to :lead_provider, inverse_of: :school_partnerships
  belongs_to :delivery_partner, inverse_of: :school_partnerships
  has_many :events

  # Validations
  validates :registration_period_id,
            presence: true,
            uniqueness: { scope: %i[lead_provider_id delivery_partner_id],
                          message: "has already been added" }

  validates :lead_provider_id,
            presence: true

  validates :delivery_partner_id,
            presence: true

end
