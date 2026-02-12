class NationalBody < ApplicationRecord
  # Independent schools in England and overseas
  ISTIP = "Independent Schools Teacher Induction Panel (ISTIP)"

  # British international schools overseas
  ESP = "Educational Success Partners (ESP)"

  # Associations
  belongs_to :dfe_sign_in_organisation
  has_one :appropriate_body_period, class_name: "AppropriateBody"

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }
end
