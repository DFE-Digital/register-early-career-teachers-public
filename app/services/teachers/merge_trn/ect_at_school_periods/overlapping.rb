module Teachers
  class MergeTRN
    module ECTAtSchoolPeriods
      class Overlapping
        include Teachers::MergeTRN::Concerns::OverlappingAtSchoolPeriod

      private

        def period_type
          :ect_at_school_period
        end
      end
    end
  end
end
