module Teachers
  class MergeTRN
    module ECTAtSchoolPeriods
      class Merge
        include Teachers::MergeTRN::Concerns::MergeableAtSchoolPeriod

        def self.call(...) = new(...).call

      private

        def period_type
          :ect_at_school_period
        end
      end
    end
  end
end
