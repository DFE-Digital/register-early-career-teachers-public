module Schools
  class Teacher
    IN_PROGRESS = 'In progress'.freeze
    UNKNOWN = 'Unknown'.freeze

    def initialize(school_urn)
      @school_urn = school_urn
    end

    def fetch_etcs_and_mentors
      ects_and_mentors.map do |ect|
        {
          ect:,
          ect_name: ::Teachers::Name.new(ect.teacher).full_name,
          ect_trn: ect.teacher.trn,
          mentor_name: ::Teachers::Name.new(ect.mentors.last&.teacher).full_name,
          status: ect_status(ect.teacher.id)
        }
      end
    end

    def fetch_ect_at_school_period_id(trn:)
      ECTAtSchoolPeriod
        .joins(:teacher, :school)
        .find_by(teacher: { trn: trn }, school: { urn: school_urn }).id
    end

  private

    attr_reader :school_urn

    def ects_and_mentors
      ECTAtSchoolPeriod
        .where(school:)
        .eager_load(:teacher, :school, mentors: :teacher)
        .merge(MentorshipPeriod.ongoing)
    end

    def ect_status(ect_id)
      ect_id.present? ? IN_PROGRESS : UNKNOWN
    end

    def school
      @school ||= School.find_by(urn: school_urn) || School.first
    end
  end
end
