module Teachers
  class MergeTRN
    module MentorAtSchoolPeriods
      class Overlapping
        include Teachers::MergeTRN::Concerns::OverlappingAtSchoolPeriod

      private

        def period_type
          :mentor_at_school_period
        end
      end
    end
  end
end
