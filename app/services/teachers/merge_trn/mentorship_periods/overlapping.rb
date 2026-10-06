module Teachers
  class MergeTRN
    module MentorshipPeriods
      class Overlapping
        include Teachers::MergeTRN::Concerns::Overlapping

      private

        def period_type
          :mentorship_period
        end
      end
    end
  end
end
