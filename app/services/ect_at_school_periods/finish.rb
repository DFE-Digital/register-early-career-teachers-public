module ECTAtSchoolPeriods
  class Finish
    attr_reader :ect_at_school_period, :finished_on, :author

    def initialize(ect_at_school_period:, finished_on:, author:)
      @ect_at_school_period = ect_at_school_period
      @finished_on = finished_on
      @author = author
    end

    def finish!
      ActiveRecord::Base.transaction do
        ect_at_school_period.update!(finished_on:)

        Events::Record.record_teacher_left_school_as_ect!(
          author:,
          ect_at_school_period:,
          happened_at: finished_on,
          **event_params
        )

        MentorshipPeriods::Finish.new(author:, mentorship_period:, finished_on:).finish! if mentorship_period.present?
        # set training_period finished_on
      end
    end

  private

    def mentorship_period
      @mentorship_period ||= ect_at_school_period.current_mentorship_period
    end

    def event_params
      {
        teacher: ect_at_school_period.teacher,
        school: ect_at_school_period.school,
        training_period: ect_at_school_period.current_training_period
      }
    end
  end
end
