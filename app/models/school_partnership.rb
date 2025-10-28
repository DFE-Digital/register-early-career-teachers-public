class SchoolPartnership < ApplicationRecord
  include DeclarativeUpdates

  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  belongs_to :school
  has_many :events
  has_many :training_periods
  has_many :ongoing_training_periods, -> { ongoing_today }, class_name: "TrainingPeriod"
  has_one :active_lead_provider, through: :lead_provider_delivery_partnership
  has_one :delivery_partner, through: :lead_provider_delivery_partnership
  has_one :contract_period, through: :active_lead_provider
  has_one :lead_provider, through: :active_lead_provider

  touch -> { self }, when_changing: %i[lead_provider_delivery_partnership_id], timestamp_attribute: :api_updated_at
  refresh_metadata -> { school }, on_event: %i[create destroy update]

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
  validates :school_id,
            presence: true,
            uniqueness: {
              scope: :lead_provider_delivery_partnership_id,
              message: 'School and lead provider delivery partnership combination must be unique'
            }

  # Scopes
  scope :for_contract_period, ->(year) { joins(:contract_period).where(contract_periods: { year: }) }
  scope :earliest_first, -> { order(created_at: 'asc') }
end
