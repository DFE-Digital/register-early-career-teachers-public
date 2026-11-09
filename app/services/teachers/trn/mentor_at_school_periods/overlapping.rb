module Teachers
  module TRN
    module MentorAtSchoolPeriods
      class Overlapping
        include Teachers::TRN::Concerns::OverlappingAtSchoolPeriod

      private

        def period_type
          :mentor_at_school_period
        end
      end
    end
  end
end
