# Name, DQT ID and type of Appropriate Body from imported legacy data
class LegacyAppropriateBody < ApplicationRecord
  # Associations
  belongs_to :appropriate_body_period, class_name: "AppropriateBody"

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  validates :dqt_id,
            presence: true,
            uniqueness: true

  enum :body_type, {
    local_authority: "local_authority",
    national: "national",
    teaching_school_hub: "teaching_school_hub"
  }, validate: {
    message: "Must be local authority, national or teaching school hub"
  }

  # Normalizations
  normalizes :name, with: -> { it.squish }
end
