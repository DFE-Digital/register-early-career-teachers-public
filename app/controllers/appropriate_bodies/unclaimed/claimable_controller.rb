module AppropriateBodies
  module Unclaimed
    class ClaimableController < BaseUnclaimedDetailsController
    private

      def initial_ect_at_school_periods
        @appropriate_body.unclaimed_ect_at_school_periods.claimable.with_teacher.with_school
      end
    end
  end
end
