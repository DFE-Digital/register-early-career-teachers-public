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
        finish_current_mentorship!
        add_new_mentorship!
        record_events!
      end
    end

  private

    def add_new_mentorship!
      @mentorship_period = ect.mentorship_periods.create!(mentor:, started_on: earliest_possible_start, finished_on: latest_possible_finish)
    end

    def earliest_possible_start
      [ect.started_on, mentor.started_on, Date.current].compact.max
    end

    def latest_possible_finish
      finish_dates = [ect.finished_on, mentor.finished_on].compact
      return nil if finish_dates.empty?

      finish_dates.min
    end

    def finish_current_mentorship!
      ECTAtSchoolPeriods::Mentorship.new(ect).current_or_next_mentorship_period&.finish!(earliest_possible_start)
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
