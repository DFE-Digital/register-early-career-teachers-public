module Admin
  module ClaimAnECT
    class ErrorsController < AdminController
      before_action :set_appropriate_body
      before_action :find_pending_induction_submission

      def exempt_from_completing_induction = nil
      def induction_already_completed = nil
      def induction_with_another_appropriate_body = nil
      def no_qts = nil
      def prohibited_from_teaching = nil

      def exempt = nil
      def completed = nil

    private

      def find_pending_induction_submission
        @pending_induction_submission = PendingInductionSubmission.find(params[:id])
      end

      def set_appropriate_body
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
      end
    end
  end
end
