module MentorAtSchoolPeriods
  class Destroy
    include Periods::Destroyable

    def initialize(mentor_at_school_period:, author:)
      @period = mentor_at_school_period
      @author = author
    end

  private

    def record_unstarted_period_deleted_event!
      Events::Record.record_teacher_mentor_at_school_period_deleted!(author:, teacher:, school:, started_on:)
    end
  end
end
