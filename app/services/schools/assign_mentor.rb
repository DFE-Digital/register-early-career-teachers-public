module Schools
  class AssignMentor
    attr_reader :ect_at_school_period, :mentor_at_school_period, :mentorship_period, :author

    def initialize(ect_at_school_period:, mentor_at_school_period:, author:, mentor_is_transferring_schools: false)
      @ect_at_school_period = ect_at_school_period
      @mentor_at_school_period = mentor_at_school_period
      @author = author
      @mentor_is_transferring_schools = mentor_is_transferring_schools
    end

    def assign!
      ActiveRecord::Base.transaction do
        close_current_and_upcoming_mentorships!
        @mentorship_period = assign_new_mentor!
        record_events!
      end
    end

  private

    def close_current_and_upcoming_mentorships!
      current_and_upcoming_mentorship_periods.each do |mentorship_period|
        if started?(mentorship_period) && earliest_possible_start.after?(mentorship_period.started_on)
          finish_mentorship!(mentorship_period)
        else
          destroy_mentorship!(mentorship_period)
        end
      end
    end

    def started?(mentorship_period) = !mentorship_period.started_on.future?

    def finish_mentorship!(mentorship_period)
      return if mentorship_period.finished_on&.before?(earliest_possible_start)

      # Since periods have inclusive range ends now, the "previous" period
      # must finish the day **before** the "new" period to avoid an overlap.
      mentorship_period.finish!(earliest_possible_start.yesterday)
    end

    def destroy_mentorship!(mentorship_period)
      Event.where(mentorship_period:).delete_all
      mentorship_period.destroy!
    end

    def current_and_upcoming_mentorship_periods
      ect_at_school_period.mentorship_periods.current_or_future.earliest_first
    end

    def assign_new_mentor!
      ect_at_school_period.mentorship_periods.create!(
        mentor: mentor_at_school_period,
        started_on: earliest_possible_start,
        finished_on: latest_possible_finish
      )
    end

    def dates_resolver
      MentorAssignment::MentorshipPeriods::DatesResolver.new(
        ect_at_school_period:,
        mentor_at_school_period:,
        mentor_is_transferring_schools:
          @mentor_is_transferring_schools
      )
    end

    def earliest_possible_start = @earliest_possible_start ||= dates_resolver.earliest_possible_start
    def latest_possible_finish = dates_resolver.latest_possible_finish

    def record_events!
      Events::Record.record_teacher_starts_being_mentored_event!(
        school: ect_at_school_period.school,
        mentee: ect_at_school_period.teacher,
        mentor: mentor_at_school_period.teacher,
        ect_at_school_period:,
        mentorship_period:,
        author:
      )
      Events::Record.record_teacher_starts_mentoring_event!(
        school: mentor_at_school_period.school,
        mentee: ect_at_school_period.teacher,
        mentor: mentor_at_school_period.teacher,
        mentor_at_school_period:,
        mentorship_period:,
        author:
      )
    end
  end
end
