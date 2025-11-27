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
    has_one :cohort, through: :school_cohort
    has_one :partnership, through: :induction_programme
    has_one :delivery_partner, through: :partnership
    has_one :lead_provider, through: :partnership

    def completed? = induction_status == "completed"
    def deferred? = training_status == "deferred"
    def flipped_dates? = end_date.present? && end_date < start_date

    def leaving? = induction_status == "leaving"

    def withdrawn? = training_status == "withdrawn"
  end
end
