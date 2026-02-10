#
# NB: This record is not production ready. Do not use until RIAB has removed this notice.
#
# An AppropriateBody is either a national body (like ISTIP) or a regional body (Teaching School Hub).
# @see LegacyAppropriateBody for details of Local authorities, who used to perform this function.
class AppropriateBody < ApplicationRecord
  # Independent schools in England and overseas
  ISTIP = "Independent Schools Teacher Induction Panel (ISTIP)"

  # British international schools overseas
  ESP = "Educational Success Partners (ESP)"

  NATIONAL_BODIES = [ISTIP, ESP].freeze

  # Scopes
  scope :national, -> { where(name: NATIONAL_BODIES) }
  scope :regional, -> { where.not(name: NATIONAL_BODIES) } # a.k.a. Teaching School Hubs

  # Associations
  belongs_to :dfe_sign_in_organisation
  has_many :appropriate_body_periods # original AppropriateBody table
  has_one :ongoing_appropriate_body_period, -> { ongoing }, class_name: "AppropriateBodyPeriod"

  # Regions and Lead School Periods are only relevant to regional  Teaching School Hubs
  has_many :regions
  has_many :lead_school_periods
  has_one :ongoing_lead_school_period, -> { ongoing }, class_name: "LeadSchoolPeriod"
  has_one :lead_school, through: :ongoing_lead_school_period, source: :school

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :dfe_sign_in_organisation, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # @return [Boolean]
  def national?
    name.in?(NATIONAL_BODIES)
  end

  # @return [Boolean]
  def teaching_school_hub?
    !national?
  end

  # @return [Array<String>]
  def districts
    regions.collect(&:districts).flatten
  end

  # @return [School, nil]
  delegate :school, to: :dfe_sign_in_organisation, prefix: :login
end
