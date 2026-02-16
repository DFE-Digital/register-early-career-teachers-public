module UnclaimedIndex
  class BaseTableRowComponent < ApplicationComponent
    def initialize(row:, ect_at_school_period:)
      @row = row
      @ect_at_school_period = ect_at_school_period
    end

  private

    attr_reader :row, :ect_at_school_period

    def teacher_name
      Teachers::Name.new(ect_at_school_period.teacher).full_name
    end

    def teacher_trn
      ect_at_school_period.trn
    end

    def school_name
      ect_at_school_period.school_name
    end

    def period_started_on
      ect_at_school_period.started_on&.to_fs(:govuk)
    end

    def induction_tutor_email
      ect_at_school_period.school.induction_tutor_email
    end
  end
end
