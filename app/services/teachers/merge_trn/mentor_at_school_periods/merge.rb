module Teachers
  class MergeTRN
    module MentorAtSchoolPeriods
      class Merge
        include Teachers::MergeTRN::Concerns::MergeableAtSchoolPeriod

        def self.call(...) = new(...).call

      private

        def period_type
          :mentor_at_school_period
        end
      end
    end
  end
end
