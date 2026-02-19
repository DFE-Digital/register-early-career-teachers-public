module AppropriateBodies
  module Unclaimed
    class NoQtsController < BaseUnclaimedDetailsController
    private

      def initial_ect_at_school_periods
        @appropriate_body.unclaimed_ect_at_school_periods.without_qts_award.with_teacher.with_school
      end
    end
  end
end
