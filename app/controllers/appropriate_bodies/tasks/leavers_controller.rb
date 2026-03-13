module AppropriateBodies
  module Tasks
    class LeaversController < BaseDetailsController
    private

      def initial_ect_at_school_periods
        @appropriate_body.claimed_ect_at_school_periods.marked_as_leaving
      end
    end
  end
end
