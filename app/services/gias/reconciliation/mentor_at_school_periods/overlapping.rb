module GIAS::Reconciliation
  module MentorAtSchoolPeriods
    class Overlapping
      include Periods::Overlapping

      def initialize(teacher:, schools:)
        @teacher = teacher
        @schools = Array(schools).compact.uniq
      end

      def find
        return [] if only_one_school?

        super
      end

    private

      attr_reader :teacher, :schools

      def ordered_periods
        @ordered_periods ||= teacher
          .mentor_at_school_periods
          .where(school: schools)
          .order(:started_on)
      end

      def only_one_school?
        schools.uniq.one? || mentor_periods_belong_to_one_school?
      end

      def mentor_periods_belong_to_one_school?
        teacher
          .mentor_at_school_periods
          .where(school: schools)
          .distinct
          .limit(2)
          .pluck(:school_id)
          .one?
      end
    end
  end
end
