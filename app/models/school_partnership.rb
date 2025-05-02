class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :lead_provider_delivery_partnership
  belongs_to :school
  has_many :events
  has_many :training_periods, inverse_of: :school_partnership
  has_one :lead_provider, through: :lead_provider_delivery_partnership
  has_one :delivery_partner, through: :lead_provider_delivery_partnership
  has_one :registration_period, through: :lead_provider_delivery_partnership
  has_one :lead_provider_active_period, through: :lead_provider_delivery_partnership

  # Validations
  validates :school, presence: true
  validates :lead_provider_delivery_partnership, presence: true, uniqueness: { scope: :school_id }

  # Scopes
  scope :for_registration_period, ->(year) { joins(lead_provider_delivery_partnership: :lead_provider_active_period).where(lead_provider_active_period: { registration_period_id: year }) }
  scope :for_lead_provider, ->(lead_provider_id) { joins(lead_provider_delivery_partnership: :lead_provider_active_period).where(lead_provider_active_period: { lead_provider_id: }) }
  scope :for_delivery_partner, ->(delivery_partner_id) { joins(:lead_provider_delivery_partnership).where(lead_provider_delivery_partnership: { delivery_partner_id: }) }
end
