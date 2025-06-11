module AppropriateBodies
  module ProcessBatch
    class ClaimsController < PendingInductionSubmissionBatchController
      def index
        @pending_induction_submission_batches = PendingInductionSubmissionBatch
            .for_appropriate_body(@appropriate_body)
            .claim
            .order(id: :desc)
      end

      def create
        @pending_induction_submission_batch = new_batch_claim

        if csv_data.valid?
          @pending_induction_submission_batch.data = csv_data.to_a
          @pending_induction_submission_batch.filename = csv_data.file_name
          @pending_induction_submission_batch.save!

          record_bulk_upload_started_event
          process_batch_claim

          redirect_to ab_batch_claim_path(@pending_induction_submission_batch)
        else
          csv_data.errors.each do |error|
            @pending_induction_submission_batch.errors.add(error.attribute, error.message)
          end

          render :new, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing
        @pending_induction_submission_batch.errors.add(:csv_file, 'Select a file')
        render :new, status: :unprocessable_entity
      rescue StandardError
        @pending_induction_submission_batch.errors.add(:base, 'Something went wrong')
        render :new, status: :unprocessable_entity
      end

      def edit
        redirect_to ab_batch_claim_path(@pending_induction_submission_batch) unless @pending_induction_submission_batch.processed?
      end

      def update
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

        process_batch_claim
        record_bulk_upload_completed_event

        redirect_to ab_batch_claim_path(@pending_induction_submission_batch)
      end

    private

      def new_batch_claim
        PendingInductionSubmissionBatch.new_claim_for(appropriate_body: @appropriate_body)
      end

      def process_batch_claim
        ProcessBatchClaimJob.perform_later(
          @pending_induction_submission_batch,
          current_user.email,
          current_user.name
        )
      end
    end
  end
end
