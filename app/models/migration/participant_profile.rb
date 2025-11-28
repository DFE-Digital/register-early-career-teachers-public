module Migration
  class ParticipantProfile < Migration::Base
    self.inheritance_column = nil

    belongs_to :teacher_profile
    belongs_to :participant_identity
    belongs_to :school_cohort
    belongs_to :schedule
    has_many :induction_records
    has_many :school_mentors # only ParticipantProfile::Mentor
    has_many :participant_declarations
    has_many :participant_profile_states

    scope :ect, -> { where(type: "ParticipantProfile::ECT") }
    scope :mentor, -> { where(type: "ParticipantProfile::Mentor") }
    scope :ect_or_mentor, -> { ect.or(mentor) }

    def ect?
      type == "ParticipantProfile::ECT"
    end

    def mentor?
      type == "ParticipantProfile::Mentor"
    end

    def previous_payments_frozen_cohort_start_year
      return nil unless cohort_changed_after_payments_frozen?

      induction_records
        .find { |ir| ir.cohort.payments_frozen? && ir.cohort.id != schedule.cohort_id }
        &.cohort&.start_year
    end
  end
end
