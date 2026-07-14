module Schools
  module MentorAssignment
    module MentorshipPeriods
      class DatesResolver
        def initialize(
          ect_at_school_period:,
          mentor_at_school_period:,
          mentorship_can_start_today:
        )
          @ect_at_school_period = ect_at_school_period
          @mentor_at_school_period = mentor_at_school_period
          @mentorship_can_start_today = mentorship_can_start_today
        end

        def earliest_possible_start
          [
            @ect_at_school_period.started_on,
            @mentor_at_school_period.started_on,
            (Date.current if @mentorship_can_start_today)
          ].compact.max
        end

        def latest_possible_finish
          [@ect_at_school_period.finished_on, @mentor_at_school_period.finished_on]
            .compact.min
        end
      end
    end
  end
end
