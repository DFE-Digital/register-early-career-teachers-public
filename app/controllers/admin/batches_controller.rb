module Admin
  class BatchesController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @pagy, @batches = pagy(
        PendingInductionSubmissionBatch.includes(:appropriate_body_period, :pending_induction_submissions)
                                      .order(created_at: :desc)
      )
    end
  end
end
