class AppropriateBody < ApplicationRecord
  # Enums
  enum :body_type,
       { local_authority: "local_authority",
         national: "national",
         teaching_school_hub: "teaching_school_hub" },
       validate: { message: "Must be local authority, national or teaching school hub" }

  # Associations
  has_many :pending_induction_submissions
  has_many :induction_periods, inverse_of: :appropriate_body
  has_many :events
  has_many :unclaimed_ect_at_school_periods,
           -> { unclaimed_by_school_reported_appropriate_body },
           class_name: "ECTAtSchoolPeriod",
           foreign_key: :school_reported_appropriate_body_id

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  normalizes :name, with: -> { it.squish }
end
