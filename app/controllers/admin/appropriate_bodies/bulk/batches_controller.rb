module Admin::AppropriateBodies
  module Bulk
    class BatchesController < AdminController
      include Pagy::Backend

      layout "full"

      before_action :set_appropriate_body

      def index
        query = PendingInductionSubmissionBatch
          .includes(:appropriate_body, :pending_induction_submissions)
          .for_appropriate_body(@appropriate_body)
          .order(created_at: :desc)

        @page, @batches = pagy(query)
      end

      def show
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])
      end

    private

      def set_appropriate_body
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
      end
    end
  end
end
