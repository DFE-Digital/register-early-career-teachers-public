class SchoolPartnership < ApplicationRecord
  include DeclarativeUpdates

  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  belongs_to :school
  has_many :events
  has_many :ongoing_training_periods, -> { ongoing_today }, class_name: "TrainingPeriod"
  has_many :training_periods
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
  scope :earliest_first, -> { order(created_at: :asc) }
  scope :for_contract_period, ->(year) { joins(:contract_period).where(contract_periods: { year: }) }
  scope :for_contract_period_year, ->(year) {
    joins(lead_provider_delivery_partnership: :active_lead_provider)
      .where(active_lead_providers: { contract_period_year: year })
  }
  scope :excluding_contract_period_year, ->(year) {
    joins(lead_provider_delivery_partnership: :active_lead_provider)
      .where.not(active_lead_providers: { contract_period_year: year })
  }
  scope :latest_by_contract_year, -> {
    joins(lead_provider_delivery_partnership: :active_lead_provider)
      .order('active_lead_providers.contract_period_year DESC, school_partnerships.created_at DESC')
  }
end
