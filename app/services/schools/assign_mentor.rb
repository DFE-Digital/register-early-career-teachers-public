module Schools
  class AssignMentor
    attr_reader :author, :ect, :mentor, :mentorship_period

    def initialize(author:, ect:, mentor:)
      @author = author
      @ect = ect
      @mentor = mentor
    end

    def assign!
      ActiveRecord::Base.transaction do
        finish_or_destroy_current_mentorship!
        add_new_mentorship!
        record_events!
      end
    end

  private

    def add_new_mentorship!
      started_on = earliest_possible_start

      if current_mentorship_period&.finished_on == started_on
        started_on = current_mentorship_period.finished_on.next_day
      end

      @mentorship_period = ect.mentorship_periods.create!(mentor:, started_on:, finished_on: latest_possible_finish)
    end

    def earliest_possible_start
      possible_dates = [ect.started_on, mentor.started_on]
      possible_dates.push(Date.current) unless mentor_moving_schools?
      possible_dates.compact.max
    end

    def latest_possible_finish
      [ect.finished_on, mentor.finished_on].compact.min
    end

    def finish_or_destroy_current_mentorship!
      return unless current_mentorship_period

      if current_mentorship_period.started_on >= earliest_possible_start
        destroy_current_mentorship_period!
      else
        current_mentorship_period.finish!(earliest_possible_start)
      end
    end

    def destroy_current_mentorship_period!
      Event.where(mentorship_period: current_mentorship_period).delete_all

      current_mentorship_period.destroy!
    end

    def mentor_moving_schools?
      previous_school_mentor_at_school_periods.exists?
    end

    def previous_school_mentor_at_school_periods
      finishes_in_the_future_scope = ::MentorAtSchoolPeriod.finished_on_or_after(mentor.started_on)
      scope = ::MentorAtSchoolPeriod.ongoing.or(finishes_in_the_future_scope)
      mentor.teacher.mentor_at_school_periods.where.not(school: ect.school).merge(scope)
    end

    def current_mentorship_period
      @current_mentorship_period ||= ECTAtSchoolPeriods::Mentorship.new(ect).current_or_next_mentorship_period
    end

    def record_events!
      common_arguments = { author:, mentorship_period: }

      Events::Record.record_teacher_starts_being_mentored_event!(
        school: ect.school,
        mentee: ect.teacher,
        mentor: mentor.teacher,
        ect_at_school_period: ect,
        **common_arguments
      )

      Events::Record.record_teacher_starts_mentoring_event!(
        school: mentor.school,
        mentor: mentor.teacher,
        mentee: ect.teacher,
        mentor_at_school_period: mentor,
        **common_arguments
      )
    end
  end
end
