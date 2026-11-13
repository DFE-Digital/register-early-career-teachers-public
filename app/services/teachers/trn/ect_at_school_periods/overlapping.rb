module Teachers
  module TRN
    module ECTAtSchoolPeriods
      class Overlapping
        include Teachers::TRN::Concerns::OverlappingAtSchoolPeriod

      private

        def period_type
          :ect_at_school_period
        end
      end
    end
  end
end
