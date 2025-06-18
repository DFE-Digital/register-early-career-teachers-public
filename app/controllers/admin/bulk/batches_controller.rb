module Admin
  module Bulk
    class BatchesController < AdminController
      layout 'full'

      def index
        @batches = PendingInductionSubmissionBatch.includes(:appropriate_body, :pending_induction_submissions)
                                                  .order(created_at: :desc)
      end

      def show
        @batch = PendingInductionSubmissionBatch.find(params[:id])
        @batch_presenter = PendingInductionSubmissionBatchPresenter.new(@batch)
      end
    end
  end
end
