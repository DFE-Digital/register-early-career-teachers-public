module Teachers
  class MergeTRN
    module MentorshipPeriods
      class Merge
        include Periods::Mergeable

        class CannotMergePeriods < StandardError; end

        def call
          raise CannotMergePeriods, "Periods have different mentors" if periods_have_different_mentors?

          super
        end

      private

        def period_type
          :mentorship_period
        end

        def successor_period
          @successor_period ||= periods
            .select { |period| period.mentee.teacher == destination }
            .max_by(&:started_on)
        end

        def teacher
          successor_period.mentee.teacher
        end

        def periods_have_different_mentors?
          periods.map(&:mentor).uniq.size > 1
        end
      end
    end
  end
end
