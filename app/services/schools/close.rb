module Schools
  class Close
    attr_reader :school

    def initialize(school)
      @school = school
    end

    def call
      return unless gias_school.closed?
      return if gias_school.gias_school_links.exists?

      destroy_unstarted_periods!
      finish_ongoing_periods!
      record_school_closed_event!
    end

  private

    def destroy_unstarted_periods!
      unstarted_mentor_at_school_periods.each do |mentor_at_school_period|
        MentorAtSchoolPeriods::Destroy.call(mentor_at_school_period:, author:)
      end

      unstarted_ect_at_school_periods.each do |ect_at_school_period|
        ECTAtSchoolPeriods::Destroy.call(ect_at_school_period:, author:)
      end
    end

    def finish_ongoing_periods!
      ongoing_mentor_at_school_periods.each do |mentor_at_school_period|
        MentorAtSchoolPeriods::Finish.new(
          teacher: mentor_at_school_period.teacher,
          reported_by_school_id:,
          finished_on:,
          author:
        )
        .finish_periods_at_reported_school!
      end

      ongoing_ect_at_school_periods.each do |ect_at_school_period|
        ECTAtSchoolPeriods::Finish.new(
          ect_at_school_period:,
          finished_on:,
          author:,
          reported_by_school_id:
        ).finish!
      end
    end

    def unstarted_mentor_at_school_periods
      mentor_at_school_periods.starting_tomorrow_or_after
    end

    def unstarted_ect_at_school_periods
      ect_at_school_periods.starting_tomorrow_or_after
    end

    def ongoing_mentor_at_school_periods
      mentor_at_school_periods.ongoing_on(Date.current)
    end

    def ongoing_ect_at_school_periods
      ect_at_school_periods.ongoing_on(Date.current)
    end

    def record_school_closed_event!
      Events::Record.record_school_closed_event!(
        school:,
        author:
      )
    end

    def author
      @author ||= Events::SystemAuthor.new
    end

    def reported_by_school_id = school.id

    def finished_on = Date.current

    delegate :ect_at_school_periods, :mentor_at_school_periods, :gias_school, to: :school
  end
end
