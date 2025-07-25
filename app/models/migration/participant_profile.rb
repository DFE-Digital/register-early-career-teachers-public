module Migration
  class ParticipantProfile < Migration::Base
    self.inheritance_column = nil

    belongs_to :teacher_profile
    belongs_to :participant_identity
    belongs_to :school_cohort
    belongs_to :schedule
    has_many :induction_records
    has_many :school_mentors # only ParticipantProfile::Mentor

    scope :ect, -> { where(type: "ParticipantProfile::ECT") }
    scope :mentor, -> { where(type: "ParticipantProfile::Mentor") }
    scope :ect_or_mentor, -> { ect.or(mentor) }

    def ect?
      type == "ParticipantProfile::ECT"
    end

    def mentor?
      type == "ParticipantProfile::Mentor"
    end
  end
end
