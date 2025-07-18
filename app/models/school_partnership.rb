class SchoolPartnership < ApplicationRecord
  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  belongs_to :school
  has_many :events

  # delegates
  delegate :lead_provider, :delivery_partner, :contract_period, to: :lead_provider_delivery_partnership

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
  validates :school_id,
            presence: true,
            uniqueness: {
              scope: :lead_provider_delivery_partnership_id,
              message: 'School and lead provider delivery partnership combination must be unique'
            }

  scope :earliest_first, -> { order(created_at: 'asc') }
end
