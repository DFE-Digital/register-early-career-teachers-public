class AppropriateBody < ApplicationRecord
  ISTIP = 'Independent Schools Teacher Induction Panel (ISTIP)'.freeze

  # Enums
  enum :body_type,
       { local_authority: 'local_authority',
         national: 'national',
         teaching_school_hub: 'teaching_school_hub' },
       validate: { message: "Must be local authority, national or teaching school hub" }

  # Associations
  has_many :pending_induction_submissions
  has_many :induction_periods, inverse_of: :appropriate_body
  has_many :events

  # Validations
  validates :name,
            presence: true,
            uniqueness: true

  validates :local_authority_code,
            presence: { message: 'Enter a local authority code', allow_blank: true },
            inclusion: {
              in: 50..999,
              message: 'Must be a number between 50 and 999',
              allow_blank: true
            },
            uniqueness: {
              scope: :establishment_number,
              message: "An appropriate body with this local authority code and establishment number already exists",
              allow_blank: true
            }

  validates :establishment_number,
            presence: { message: 'Enter a establishment number', allow_blank: true },
            inclusion: {
              in: 1000..9999,
              message: 'Must be a number between 1000 and 9999',
              allow_blank: true
            }

  def self.istip
    find_by_name(ISTIP)
  end
end
