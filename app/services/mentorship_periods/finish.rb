module MentorshipPeriods
  class Finish
    attr_reader :mentorship_period, :finished_on, :author, :ect_at_school_period, :mentor_at_school_period

    def initialize(mentorship_period:, finished_on:, author:, record_event: true)
      @mentorship_period = mentorship_period
      @finished_on = finished_on
      @author = author

      @ect_at_school_period = mentorship_period.mentee
      @mentor_at_school_period = mentorship_period.mentor
      @record_event = record_event
    end

    def finish!
      ActiveRecord::Base.transaction do
        mentorship_period.update!(finished_on:)

        record_finish_events!
      end
    end

  private

    def record_finish_events!
      return unless record_event?

      Events::Record.record_teacher_finishes_mentoring_event!(
        author:,
        mentorship_period:,
        mentor_at_school_period:,
        school: mentor_at_school_period.school,
        happened_at: finished_on,
        mentee: ect_at_school_period.teacher,
        mentor: mentor_at_school_period.teacher
      )

      Events::Record.record_teacher_finishes_being_mentored_event!(
        author:,
        mentorship_period:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        happened_at: finished_on,
        mentee: ect_at_school_period.teacher,
        mentor: mentor_at_school_period.teacher
      )
    end

    def record_event?
      @record_event
    end
  end
end
