module Teachers
  class MergeTRN
    module Concerns
      module OverlappingAtSchoolPeriod
        extend ActiveSupport::Concern

        include Teachers::MergeTRN::Concerns::Overlapping

      private

        def periods_by_school
          ordered_periods.group_by(&:school_id).values
        end

        def group_periods = group_by_school

        def group_by_school
          periods_by_school.each do |periods|
            group_by_order(periods)
          end
        end

        def start_new_group?(current_group, next_period)
          return true if next_period_at_different_school?(current_group, next_period)

          super
        end

        def next_period_at_different_school?(current_group, next_period)
          return unless current_group

          current_group.last.school_id != next_period.school_id
        end
      end
    end
  end
end
