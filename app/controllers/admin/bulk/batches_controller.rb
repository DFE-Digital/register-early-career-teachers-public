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
    end
  end
end
