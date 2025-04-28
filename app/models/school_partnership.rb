class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :lead_provider_delivery_partnership
  belongs_to :school
  belongs_to :registration_period, inverse_of: :school_partnerships
  belongs_to :lead_provider, inverse_of: :school_partnerships
  belongs_to :delivery_partner, inverse_of: :school_partnerships
  has_many :events

  # Validations
  validates :school, presence: true

  validates :registration_period_id,
            presence: true,
            uniqueness: { scope: %i[lead_provider_id delivery_partner_id],
                          message: "has already been added" }

  validates :lead_provider_id,
            presence: true

  validates :delivery_partner_id,
            presence: true

  # Scopes
  scope :for_registration_period, ->(year) { where(registration_period_id: year) }
  scope :for_lead_provider, ->(lead_provider_id) { where(lead_provider_id:) }
  scope :for_delivery_partner, ->(delivery_partner_id) { where(delivery_partner_id:) }
end
