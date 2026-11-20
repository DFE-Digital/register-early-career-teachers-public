module Admin
  class BatchesController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @pagy, @batches = pagy(
        PendingInductionSubmissionBatch
          .with_appropriate_body_display_names
          .includes(:pending_induction_submissions)
          .order(created_at: :desc)
      )
    end
  end
end
