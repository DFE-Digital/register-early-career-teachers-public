module GIAS::Schools
  module MentorAtSchoolPeriods
    class Overlapping
      def self.find(...) = new(...).find

      def initialize(teacher:, schools:)
        @teacher = teacher
        @schools = Array(schools).compact.uniq
        @groups = []
      end

      def find
        return [] if only_one_school?

        group_mentor_at_school_periods

        groups.select(&:many?)
      end

    private

      attr_reader :teacher, :schools, :groups

      def ordered_mentor_at_school_periods
        @ordered_mentor_at_school_periods ||= teacher
          .mentor_at_school_periods
          .where(school: schools)
          .order(:started_on)
      end

      def only_one_school?
        schools.uniq.one? || ordered_mentor_at_school_periods.map(&:school_id).uniq.one?
      end

      def group_mentor_at_school_periods
        ordered_mentor_at_school_periods.each do |period|
          if start_new_group?(groups.last, period)
            groups << [period]
          else
            groups.last << period
          end
        end
      end

      def start_new_group?(current_group, next_period)
        current_group.nil? || gap_between?(current_group, next_period)
      end

      def gap_between?(group, period)
        return false if group.any?(&:unfinished?)

        group.map(&:finished_on).max < period.started_on
      end
    end
  end
end
