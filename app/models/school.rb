class School < ApplicationRecord
  # Enums
  enum :chosen_programme_type,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be nil or provider-led or school-led",
                   allow_nil: true },
       suffix: :programme_type_chosen

  # Associations
  belongs_to :gias_school, class_name: "GIAS::School", foreign_key: :urn, inverse_of: :school
  belongs_to :chosen_appropriate_body, class_name: 'AppropriateBody'
  belongs_to :chosen_lead_provider, class_name: 'LeadProvider'

  has_many :ect_at_school_periods, inverse_of: :school
  has_many :ect_teachers, -> { distinct }, through: :ect_at_school_periods, source: :teacher
  has_many :events
  has_many :mentor_at_school_periods, inverse_of: :school
  has_many :mentor_teachers, -> { distinct }, through: :mentor_at_school_periods, source: :teacher
  has_many :school_partnerships

  # Validations
  validates :chosen_lead_provider_id,
            presence: {
              message: 'Must contain the id of a lead provider',
              if: -> { provider_led_programme_type_chosen? }
            },
            absence: {
              message: 'Must be nil',
              unless: -> { provider_led_programme_type_chosen? }
            }

  validates :chosen_programme_type,
            presence: {
              message: 'Must be provider-led',
              if: -> { chosen_lead_provider_id }
            }

  validate :chosen_appropriate_body_for_independent_school,
           if: -> { independent? }

  validate :chosen_appropriate_body_for_state_funded_school,
           if: -> { state_funded? }

  validates :urn,
            presence: true,
            uniqueness: true

  # Scopes
  scope :search, ->(q) { includes(:gias_school).merge(GIAS::School.search(q)) }

  # Instance Methods
  delegate :address_line1,
           :address_line2,
           :address_line3,
           :administrative_district_name,
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

  # chosen_appropriate_body_name
  delegate :name, to: :chosen_appropriate_body, prefix: true, allow_nil: true

  def chosen_appropriate_body_type = chosen_appropriate_body&.body_type

  # chosen_lead_provider_name
  delegate :name, to: :chosen_lead_provider, prefix: true, allow_nil: true

  def independent? = GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(type_name)

  def programme_choices
    {
      appropriate_body_id: chosen_appropriate_body_id,
      programme_type: chosen_programme_type,
      lead_provider_id: chosen_lead_provider_id
    }.compact
  end

  def programme_choices? = chosen_appropriate_body_id && chosen_programme_type

  def state_funded? = GIAS::Types::STATE_SCHOOL_TYPES.include?(type_name)

  def chosen_appropriate_body_for_independent_school
    return unless chosen_appropriate_body&.local_authority?

    errors.add(:chosen_appropriate_body_id, 'Must be national or teaching school hub')
  end

  def chosen_appropriate_body_for_state_funded_school
    return if chosen_appropriate_body.blank?
    return if chosen_appropriate_body.teaching_school_hub?

    errors.add(:chosen_appropriate_body_id, 'Must be teaching school hub')
  end

  def to_param = urn
end
