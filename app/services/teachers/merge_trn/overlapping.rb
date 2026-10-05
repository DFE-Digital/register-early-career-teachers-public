module Teachers
  class MergeTRN
    class Overlapping
      def self.find(...) = new(...).find

      def initialize(periods:)
        @periods = periods
        @groups = []
      end

      def find
        return [] if periods.empty?
        raise ArgumentError, "Periods must be of the same type" if different_period_types?

        group_periods

        groups.select(&:many?)
      end

    private

      attr_reader :periods, :groups

      def period_types
        periods.map(&:class).uniq
      end

      def different_period_types?
        period_types.size > 1
      end

      def period_type
        period_types.first.to_s.underscore.to_sym
      end

      def at_school_period?
        %i[mentor_at_school_period ect_at_school_period].include?(period_type)
      end

      def group_periods
        at_school_period? ? group_by_school : group_by_order
      end

      def ordered_periods
        periods.sort_by(&:started_on)
      end

      def periods_by_school
        ordered_periods.group_by(&:school_id).values
      end

      def group_by_school
        periods_by_school.each do |periods|
          group_by_order(periods)
        end
      end

      def group_by_order(periods = ordered_periods)
        periods.each do |period|
          if start_new_group?(groups.last, period)
            groups << [period]
          else
            groups.last << period
          end
        end
      end

      def start_new_group?(current_group, next_period)
        return true if current_group.nil?
        return true if next_period_at_different_school?(current_group, next_period)

        gap_between?(current_group, next_period)
      end

      def next_period_at_different_school?(current_group, next_period)
        return unless at_school_period?

        current_group.last.school_id != next_period.school_id
      end

      def gap_between?(group, period)
        return false if group.any?(&:unfinished?)

        group.map(&:finished_on).max < period.started_on
      end
    end
  end
end
