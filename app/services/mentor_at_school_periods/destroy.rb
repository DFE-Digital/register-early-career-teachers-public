module MentorAtSchoolPeriods
  class Destroy
    include Periods::Destroyable

    def initialize(mentor_at_school_period:, author:, actioned_at:)
      @period = mentor_at_school_period
      @author = author
      @actioned_at = actioned_at
    end

  private

    def record_unstarted_period_deleted_event!
      Events::Record.record_teacher_mentor_at_school_period_deleted!(author:, teacher:, school:, started_on:, happened_at: actioned_at)
    end
  end
end
