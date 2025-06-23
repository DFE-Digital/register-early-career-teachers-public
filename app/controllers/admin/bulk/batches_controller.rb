module Admin
  module Bulk
    class BatchesController < AdminController
      include Pagy::Backend

      layout 'full'

      def index
        @pagy, @batches = pagy(
          PendingInductionSubmissionBatch.includes(:appropriate_body, :pending_induction_submissions)
                                        .order(created_at: :desc)
        )
      end

      def show
        @batch = PendingInductionSubmissionBatch.find(params[:id])
        @batch_presenter = PendingInductionSubmissionBatchPresenter.new(@batch)
      end
    end
  end
end
