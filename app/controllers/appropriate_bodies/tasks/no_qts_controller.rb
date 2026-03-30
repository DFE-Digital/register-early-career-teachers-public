module AppropriateBodies
  module Tasks
    class NoQtsController < BaseDetailsController
    private

      def initial_ect_at_school_periods
        @appropriate_body.unclaimed_ect_at_school_periods.without_qts_award.with_teacher.with_school
      end
    end
  end
end
