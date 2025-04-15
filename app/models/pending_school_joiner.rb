class PendingSchoolJoiner < ApplicationRecord
  # from ECTAtSchoolPeriod
  enum :programme_type,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider-led or school-led" },
       suffix: :programme_type

  enum :role_type,
    { ect: "ect", mentor: "mentor" },
    validate: { message: "Must be ECT or mentor" },
    suffix: :role_type

  belongs_to :teacher, inverse_of: :pending_school_starts
  belongs_to :school, inverse_of: :pending_school_joiners

  belongs_to :mentor_at_school_period, optional: true
  belongs_to :lead_provider, inverse_of: :pending_school_joiners, optional: true
  belongs_to :appropriate_body, optional: true

  # TODO: check for future date too
  validates :starting_on, presence: { message: "Must have a starting_on date" }
end
