module Teachers
  class MergeTRN
    module MentorAtSchoolPeriods
      class Merge
        include Teachers::MergeTRN::Concerns::MergeableAtSchoolPeriod

      private

        def period_type
          :mentor_at_school_period
        end

        def update_mentorship_periods!
          mentorship_periods.each { |period| period.update!(mentorship_attrs) }
        end
      end
    end
  end
end
