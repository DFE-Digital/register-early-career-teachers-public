module GIAS::Schools
  class Close
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def close!
      return unless gias_school.closed?
      return if gias_school.successors.any?
      return if school_already_closed?

      ActiveRecord::Base.transaction do
        destroy_unstarted_periods!
        finish_ongoing_periods!

        record_school_closed_event!
      end
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
        gias_school:,
        happened_at: gias_school.closed_on,
        author:
      )
    end

    def author
      Events::SystemAuthor.new
    end

    def reported_by_school_id = school.id

    def finished_on = Date.current

    # If the school was closed before the service was launched no school record would have been created
    def school_already_closed?
      Event.where(school:, event_type: :school_closed).exists? || gias_school.school.blank?
    end

    delegate :school, to: :gias_school
    delegate :ect_at_school_periods, :mentor_at_school_periods, to: :school
  end
end
