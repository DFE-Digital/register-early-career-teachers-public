module ECTAtSchoolPeriods
  class ChangeStartDate
    class Eligibility
      attr_reader :ect_at_school_period

      def initialize(ect_at_school_period:)
        @ect_at_school_period = ect_at_school_period
      end

      def eligible?
        latest_ect_at_school_period? &&
          exactly_one_training_period?
      end

    private

      def latest_ect_at_school_period?
        ect_at_school_period ==
          ect_at_school_period.teacher.latest_ect_at_school_period
      end

      def exactly_one_training_period?
        ect_at_school_period.training_periods.one?
      end
    end
  end
end
