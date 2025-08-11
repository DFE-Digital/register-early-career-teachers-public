class School < ApplicationRecord
  include GIASHelpers
  include DeclarativeTouch

  touch -> { self }, when_changing: %i[urn], timestamp_attribute: :api_updated_at

  # Enums
  enum :last_chosen_training_programme,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be nil or provider-led or school-led",
                   allow_nil: true },
       suffix: :training_programme_chosen

  # Associations
  belongs_to :gias_school, class_name: "GIAS::School", foreign_key: :urn, inverse_of: :school
  belongs_to :last_chosen_appropriate_body, class_name: 'AppropriateBody'
  belongs_to :last_chosen_lead_provider, class_name: 'LeadProvider'

  has_many :ect_at_school_periods, inverse_of: :school
  has_many :ect_teachers, -> { distinct }, through: :ect_at_school_periods, source: :teacher
  has_many :events
  has_many :mentor_at_school_periods, inverse_of: :school
  has_many :mentor_teachers, -> { distinct }, through: :mentor_at_school_periods, source: :teacher
  has_many :school_partnerships

  # Validations
  validates :last_chosen_lead_provider_id,
            presence: {
              message: 'Must contain the id of a lead provider',
              if: -> { provider_led_training_programme_chosen? }
            },
            absence: {
              message: 'Must be nil',
              unless: -> { provider_led_training_programme_chosen? }
            }

  validates :last_chosen_training_programme,
            presence: {
              message: 'Must be provider-led',
              if: -> { last_chosen_lead_provider_id }
            }

  validate :last_chosen_appropriate_body_for_independent_school,
           if: -> { independent? }

  validate :last_chosen_appropriate_body_for_state_funded_school,
           if: -> { state_funded? }

  validates :urn,
            presence: true,
            uniqueness: true

  validates :induction_tutor_name,
            presence: { message: "Must provide name if induction tutor email is set" },
            if: :induction_tutor_email

  validates :induction_tutor_email,
            presence: { message: "Must provide email if induction tutor name is set" },
            if: :induction_tutor_name

  validates :induction_tutor_email,
            notify_email: true,
            allow_nil: true

  # Scopes
  scope :search, ->(q) { includes(:gias_school).merge(GIAS::School.search(q)) }

  # Instance Methods
  delegate :address_line1,
           :address_line2,
           :address_line3,
           :administrative_district_name,
           :api_id,
           :closed_on,
           :establishment_number,
           :funding_eligibility,
           :induction_eligibility,
           :in_england,
           :local_authority_code,
           :local_authority_name,
           :name,
           :opened_on,
           :primary_contact_email,
           :phase_name,
           :postcode,
           :secondary_contact_email,
           :section_41_approved,
           :status,
           :type_name,
           :ukprn,
           :website,
           to: :gias_school,
           allow_nil: true

  # last_chosen_appropriate_body_name
  delegate :name, to: :last_chosen_appropriate_body, prefix: true, allow_nil: true

  def last_chosen_appropriate_body_type = last_chosen_appropriate_body&.body_type

  # last_chosen_lead_provider_name
  delegate :name, to: :last_chosen_lead_provider, prefix: true, allow_nil: true

  def last_chosen_appropriate_body_for_independent_school
    return unless last_chosen_appropriate_body&.local_authority?

    errors.add(:last_chosen_appropriate_body_id, 'Must be national or teaching school hub')
  end

  def last_chosen_appropriate_body_for_state_funded_school
    return if last_chosen_appropriate_body.blank?
    return if last_chosen_appropriate_body.teaching_school_hub?

    errors.add(:last_chosen_appropriate_body_id, 'Must be teaching school hub')
  end

  def last_programme_choices
    {
      appropriate_body_id: last_chosen_appropriate_body_id,
      training_programme: last_chosen_training_programme,
      lead_provider_id: last_chosen_lead_provider_id
    }.compact
  end

  def last_programme_choices? = last_chosen_appropriate_body_id && last_chosen_training_programme

  def to_param = urn

  def training_programme_for(contract_period_year)
    Schools::TrainingProgramme.new(school: self, contract_period_year:).training_programme
  end

  def expression_of_interest_for?(lead_provider_id, contract_period_year)
    [ect_at_school_periods, mentor_at_school_periods].any? do |periods|
      periods.with_expressions_of_interest_for_lead_provider_and_contract_period(contract_period_year, lead_provider_id).exists?
    end
  end
end
