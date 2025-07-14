module Admin
  module ImportECT
    class ErrorsController < AdminController
      def no_qts
        @pending_induction_submission = find_pending_induction_submission
      end

      def prohibited_from_teaching
        @pending_induction_submission = find_pending_induction_submission
      end

      def induction_already_completed
        @pending_induction_submission = find_pending_induction_submission
      end

    private

      def find_pending_induction_submission
        PendingInductionSubmission.find(params[:id])
      end
    end
  end
end
