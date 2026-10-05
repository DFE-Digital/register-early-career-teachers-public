module Teachers
  class MergeTRN
    module MentorAtSchoolPeriods
      class Merge
        include Periods::Mergeable
        include Teachers::MergeTRN::Concerns::MergeableAtSchoolPeriod

      private

        def period_type
          :mentor_at_school_period
        end
      end
    end
  end
end
