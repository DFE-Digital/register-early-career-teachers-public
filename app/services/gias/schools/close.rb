module GIAS::Schools
  class Close
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def close!
      return false unless gias_school.closeable?

      close_school!

      true
    end

  private

    def close_school!
      ActiveRecord::Base.transaction do
        destroy_unstarted_mentorship_periods!
        destroy_unstarted_periods!
        finish_ongoing_periods!

        record_school_closed_event!
      end
    end

    def destroy_unstarted_periods!
      unstarted_mentor_at_school_periods.each do |mentor_at_school_period|
        MentorAtSchoolPeriods::Destroy.call(mentor_at_school_period:, author:, actioned_at: gias_school.closed_on)
      end

      unstarted_ect_at_school_periods.each do |ect_at_school_period|
        ECTAtSchoolPeriods::Destroy.call(ect_at_school_period:, author:, actioned_at: gias_school.closed_on)
      end
    end

    def destroy_unstarted_mentorship_periods!
      unstarted_mentorship_periods_at_school.each(&:destroy!)
    end

    def unstarted_mentorship_periods_at_school
      unstarted_mentorship_periods_for_ect_at_school_periods + unstarted_mentorship_periods_for_mentor_at_school_periods
    end

    def unstarted_mentorship_periods_for_ect_at_school_periods
      MentorshipPeriod.started_after(gias_school.closed_on).joins(:mentee).where(ect_at_school_periods: { school_id: school.id })
    end

    def unstarted_mentorship_periods_for_mentor_at_school_periods
      MentorshipPeriod.started_after(gias_school.closed_on).joins(:mentor).where(mentor_at_school_periods: { school_id: school.id })
    end

    def finish_ongoing_periods!
      ongoing_ect_at_school_periods.each do |ect_at_school_period|
        ECTAtSchoolPeriods::Finish.new(
          ect_at_school_period:,
          finished_on: gias_school.closed_on,
          author:,
          reported_by_school_id:
        ).finish!
      end

      ongoing_mentor_at_school_periods.each do |mentor_at_school_period|
        MentorAtSchoolPeriods::Finish.new(
          teacher: mentor_at_school_period.teacher,
          reported_by_school_id:,
          finished_on: gias_school.closed_on,
          author:
        )
        .finish_periods_at_reported_school!
      end
    end

    def unstarted_mentor_at_school_periods
      mentor_at_school_periods.started_after(gias_school.closed_on)
    end

    def unstarted_ect_at_school_periods
      ect_at_school_periods.started_after(gias_school.closed_on)
    end

    def ongoing_mentor_at_school_periods
      mentor_at_school_periods.ongoing_on(gias_school.closed_on)
    end

    def ongoing_ect_at_school_periods
      ect_at_school_periods.ongoing_on(gias_school.closed_on)
    end

    def record_school_closed_event!
      Events::Record.record_school_closed_event!(
        school:,
        gias_school:,
        happened_at: gias_school.closed_on,
        author:
      )
    end

    def author
      Events::SystemAuthor.new
    end

    def reported_by_school_id = school.id

    delegate :school, to: :gias_school
    delegate :ect_at_school_periods, :mentor_at_school_periods, to: :school
  end
end
