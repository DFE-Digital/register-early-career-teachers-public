module Schools
  module MentorAssignment
    module MentorshipPeriods
      class DatesResolver
        def initialize(
          ect_at_school_period:,
          mentor_at_school_period:,
          mentor_is_transferring_schools:
        )
          @ect_at_school_period = ect_at_school_period
          @mentor_at_school_period = mentor_at_school_period
          @mentor_is_transferring_schools = mentor_is_transferring_schools
        end

        def earliest_possible_start
          [
            @ect_at_school_period.started_on,
            @mentor_at_school_period.started_on,
            (Date.current unless backdating_allowed?)
          ].compact.max
        end

        def latest_possible_finish
          [@ect_at_school_period.finished_on, @mentor_at_school_period.finished_on]
            .compact.min
        end

      private

        def backdating_allowed?
          @mentor_is_transferring_schools &&
            @ect_at_school_period.mentorship_periods.none?
        end
      end
    end
  end
end
