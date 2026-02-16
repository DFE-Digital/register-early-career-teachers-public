module AppropriateBodies
  module Unclaimed
    class ClaimedByAnotherController < BaseUnclaimedDetailsController
    private

      def initial_ect_at_school_periods
        @appropriate_body.unclaimed_ect_at_school_periods.claimed_by_different_appropriate_body.with_teacher_current_induction_period_appropriate_body.with_school
      end
    end
  end
end
