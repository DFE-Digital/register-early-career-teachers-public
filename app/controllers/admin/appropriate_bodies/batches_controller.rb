module Admin::AppropriateBodies
  class BatchesController < AdminController
    include Pagy::Backend

    layout "full"

    before_action :set_appropriate_body

    def index
      query = PendingInductionSubmissionBatch
        .includes({ appropriate_body_period: AppropriateBodyPeriod.body_type_associations },
                  :pending_induction_submissions)
        .strict_loading
        .for_appropriate_body_period(@appropriate_body)
        .order(created_at: :desc)

      @page, @batches = pagy(query)
    end

    def show
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.for_appropriate_body_period(@appropriate_body).find(params[:id])
    end

  private

    def set_appropriate_body
      @appropriate_body = AppropriateBodyPeriod.find(params[:appropriate_body_id])
    end
  end
end
