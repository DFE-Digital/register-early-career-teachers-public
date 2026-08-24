class SchoolPartnership < ApplicationRecord
  include DeclarativeUpdates

  # Associations
  belongs_to :lead_provider_delivery_partnership, inverse_of: :school_partnerships
  belongs_to :school
  has_many :events
  has_many :ongoing_training_periods, -> { contains_today }, class_name: "TrainingPeriod"
  has_many :training_periods
  has_many :declarations, through: :training_periods
  has_one :framework_agreement, through: :lead_provider_delivery_partnership
  has_one :delivery_partner, through: :lead_provider_delivery_partnership
  has_one :contract_period, through: :framework_agreement
  has_one :lead_provider, through: :framework_agreement

  touch -> { self }, when_changing: %i[lead_provider_delivery_partnership_id], timestamp_attribute: :api_updated_at
  touch -> { declarations }, when_changing: %i[lead_provider_delivery_partnership_id], timestamp_attribute: :api_updated_at
  touch -> { teachers }, when_changing: %i[lead_provider_delivery_partnership_id], timestamp_attribute: :api_updated_at
  refresh_metadata -> { school }, on_event: %i[create destroy update]
  # if the school_id changes, refresh the metadata for the previous school
  refresh_metadata -> { School.find_by(id: school_id_before_last_save) }, on_event: %i[update], when_changing: %i[school_id]

  # Validations
  validates :lead_provider_delivery_partnership_id, presence: true
  validates :school_id,
            presence: true,
            uniqueness: {
              scope: :lead_provider_delivery_partnership_id,
              message: "School and lead provider delivery partnership combination must be unique"
            }

  # Scopes
  scope :earliest_first, -> { order(created_at: :asc) }
  scope :for_contract_period, ->(year) { joins(:contract_period).where(contract_periods: { year: }) }
  scope :for_contract_period_year, ->(year) {
    joins(lead_provider_delivery_partnership: :framework_agreement)
      .where(active_lead_providers: { contract_period_year: year })
  }
  scope :excluding_contract_period_year, ->(year) {
    joins(lead_provider_delivery_partnership: :framework_agreement)
      .where.not(active_lead_providers: { contract_period_year: year })
  }
  scope :latest_by_contract_year, -> {
    joins(lead_provider_delivery_partnership: :framework_agreement)
      .order("active_lead_providers.contract_period_year DESC, school_partnerships.created_at DESC")
  }

  def teachers
    Teacher.with_training_periods(training_periods)
  end
end
