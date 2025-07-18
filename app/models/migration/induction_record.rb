module Migration
  class InductionRecord < Migration::Base
    belongs_to :participant_profile
    belongs_to :induction_programme
    belongs_to :appropriate_body
    belongs_to :mentor_profile, class_name: "Migration::ParticipantProfile"
    belongs_to :schedule
    belongs_to :preferred_identity, class_name: "Migration::ParticipantIdentity"

    has_one :school_cohort, through: :induction_programme
    has_one :school, through: :school_cohort
    has_one :partnership, through: :induction_programme
    has_one :delivery_partner, through: :partnership
    has_one :lead_provider, through: :partnership
  end
end
