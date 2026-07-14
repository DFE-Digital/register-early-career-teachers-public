module Schools
  class AssignMentor
    attr_reader :ect_at_school_period, :mentor_at_school_period, :mentorship_period, :author

    def initialize(ect_at_school_period:, mentor_at_school_period:, author:, mentorship_can_start_today: true)
      @ect_at_school_period = ect_at_school_period
      @mentor_at_school_period = mentor_at_school_period
      @author = author
      @mentorship_can_start_today = mentorship_can_start_today
    end

    def assign!
      ActiveRecord::Base.transaction do
        close_current_mentorship!
        @mentorship_period = assign_new_mentor!
        record_events!
      end
    end

  private

    def close_current_mentorship!
      return unless current_ect_mentorship_period

      if earliest_possible_start.after?(current_ect_mentorship_period.started_on)
        finish_current_mentorship!
      else
        destroy_current_mentorship!
      end
    end

    def finish_current_mentorship!
      # Since periods have inclusive range ends now, the "previous" period
      # must finish the day **before** the "new" period to avoid an overlap.
      current_ect_mentorship_period.finish!(earliest_possible_start.yesterday)
    end

    def destroy_current_mentorship!
      Event.where(mentorship_period: current_ect_mentorship_period).delete_all
      current_ect_mentorship_period.destroy!
    end

    def current_ect_mentorship_period
      ect_at_school_period.current_or_next_mentorship_period
    end

    def assign_new_mentor!
      ect_at_school_period.mentorship_periods.create!(
        mentor: mentor_at_school_period,
        started_on: earliest_possible_start,
        finished_on: latest_possible_finish
      )
    end

    def earliest_possible_start
      possible_dates = [ect_at_school_period.started_on, mentor_at_school_period.started_on]
      possible_dates.push(Date.current) if @mentorship_can_start_today
      possible_dates.compact.max
    end

    def latest_possible_finish
      [ect_at_school_period.finished_on, mentor_at_school_period.finished_on].compact.min
    end

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
