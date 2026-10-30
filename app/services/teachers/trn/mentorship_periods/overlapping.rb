module Teachers
  module TRN
    module MentorshipPeriods
      class Overlapping
        include Teachers::TRN::Concerns::Overlapping

      private

        def period_type
          :mentorship_period
        end
      end
    end
  end
end
