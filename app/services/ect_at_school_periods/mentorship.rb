module ECTAtSchoolPeriods
  class Mentorship
    attr_reader :ect_at_school_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    delegate :current_mentorship_period, to: :ect_at_school_period, allow_nil: true
    delegate :mentor, to: :current_mentorship_period, allow_nil: true, prefix: :current

    def current_mentor_name
      @current_mentor_name ||= Teachers::Name.new(current_mentor.teacher).full_name if current_mentor
    end
  end
end
