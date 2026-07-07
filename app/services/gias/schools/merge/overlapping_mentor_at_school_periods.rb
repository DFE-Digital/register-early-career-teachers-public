module GIAS
  module Schools
    class Merge
      class OverlappingMentorAtSchoolPeriods
        attr_reader :teacher, :schools, :groups

        def initialize(teacher:, schools:)
          @teacher = teacher
          @schools = Array(schools).compact.uniq
          @groups = []
        end

        def self.find(...) = new(...).find

        def find
          group_mentor_at_school_periods

          groups.select(&:many?)
        end

      private

        def ordered_mentor_at_school_periods
          @ordered_mentor_at_school_periods ||= teacher
            .mentor_at_school_periods
            .where(school: schools)
            .order(:started_on)
            .to_a
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

        def start_new_group?(current_group, current_period)
          current_group.nil? || gap_between?(current_group, current_period)
        end

        def gap_between?(group, period)
          return false if group.any?(&:ongoing?)

          group.map(&:finished_on).max + 1.day < period.started_on
        end
      end
    end
  end
end
