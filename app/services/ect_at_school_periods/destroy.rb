module ECTAtSchoolPeriods
  class Destroy
    include Periods::Destroyable

    def initialize(ect_at_school_period:, author:, actioned_at:)
      @period = ect_at_school_period
      @author = author
      @actioned_at = actioned_at
    end

  private

    def record_unstarted_period_deleted_event!
      Events::Record.record_teacher_ect_at_school_period_deleted!(author:, teacher:, school:, started_on:, happened_at: actioned_at)
    end
  end
end
