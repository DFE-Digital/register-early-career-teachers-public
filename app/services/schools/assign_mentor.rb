module Schools
  class AssignMentor
    attr_reader :author, :ect, :mentor, :started_on, :mentorship_period

    def initialize(author:, ect:, mentor:, started_on: Date.current)
      @author = author
      @ect = ect
      @mentor = mentor
      @started_on = started_on
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
      @mentorship_period = ect.mentorship_periods.create!(mentor:, started_on:)
    end

    def finish_current_mentorship!
      ect.current_mentorship&.finish!(started_on)
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
