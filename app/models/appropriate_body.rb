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
  has_many :regions

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :dfe_sign_in_organisation, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # @return [Array<String>]
  def districts
    regions.collect(&:districts).flatten
  end

  # @return [School]
  delegate :school, to: :dfe_sign_in_organisation, prefix: :lead
end
