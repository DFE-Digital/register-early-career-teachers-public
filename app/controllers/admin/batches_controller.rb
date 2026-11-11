module Admin
  class BatchesController < AdminController
    include Pagy::Backend

    layout "full"

    def index
      @pagy, @batches = pagy(
        PendingInductionSubmissionBatch
          .includes({ appropriate_body_period: AppropriateBodyPeriod.body_type_associations },
                    :pending_induction_submissions)
          .strict_loading
          .order(created_at: :desc)
      )
    end
  end
end
