class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  belongs_to :school
  has_many :events
  has_one :active_lead_provider, through: :lead_provider_delivery_partnership
  has_one :contract_period, through: :active_lead_provider

  # delegates
  delegate :lead_provider, :delivery_partner, to: :lead_provider_delivery_partnership

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
  validates :school_id,
            presence: true,
            uniqueness: {
              scope: :lead_provider_delivery_partnership_id,
              message: 'School and lead provider delivery partnership combination must be unique'
            }

  # Scopes
  scope :earliest_first, -> { order(created_at: 'asc') }
  scope :for_contract_period, ->(year) { joins(:contract_period).where(contract_periods: { year: }) }
end
