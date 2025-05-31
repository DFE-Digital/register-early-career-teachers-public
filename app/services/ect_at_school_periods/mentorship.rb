module ECTAtSchoolPeriods
  class Mentorship
    attr_reader :ect_at_school_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    def current_mentorship_period
      latest_mentorship_period if latest_mentorship_period&.ongoing?
    end

    def latest_mentorship_period
      @latest_mentorship_period ||= ect_at_school_period.mentorship_periods
                                                        .started_before(Date.tomorrow)
                                                        .latest_first
                                                        .first
    end

    # current_mentor
    delegate :mentor, to: :current_mentorship_period, allow_nil: true, prefix: :current

    def current_mentor_name
      @current_mentor_name ||= Teachers::Name.new(current_mentor.teacher).full_name if current_mentor
    end

    # latest_mentor
    delegate :mentor, to: :latest_mentorship_period, allow_nil: true, prefix: :latest

    def latest_mentor_name
      @latest_mentor_name ||= Teachers::Name.new(latest_mentor.teacher).full_name if latest_mentor
    end
  end
end
