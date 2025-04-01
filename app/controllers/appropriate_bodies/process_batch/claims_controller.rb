module AppropriateBodies
  module ProcessBatch
    class ClaimsController < PendingInductionSubmissionBatchController
      def index
        @pending_induction_submission_batches =
          PendingInductionSubmissionBatch
            .claim
            .for_appropriate_body(@appropriate_body.id)
            .order(id: :desc)
            .select(:id, :batch_type, :batch_status, :error_message)
            .map { |b| b.attributes.values.map(&:to_s) }
      end

      def create
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.new_claim_for(appropriate_body: @appropriate_body, **import_params)
        # PendingInductionSubmissionBatch.new(
        #   appropriate_body: @appropriate_body,
        #   batch_type: 'claim',
        #   **import_params
        # )

        if @pending_induction_submission_batch.save! && @pending_induction_submission_batch.save(context: :uploaded)
          ProcessBatchClaimJob.perform_later(@pending_induction_submission_batch, current_user.email, current_user.name)

          redirect_to ab_batch_claim_path(@pending_induction_submission_batch), alert: 'File uploaded'
        else
          render :new
        end
      rescue ActionController::ParameterMissing, ActiveStorage::FileNotFoundError
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.new
        @pending_induction_submission_batch.errors.add(:csv_file, "Attach a CSV file")
        render :new
      rescue StandardError => e
        @pending_induction_submission_batch ||= PendingInductionSubmissionBatch.new
        @pending_induction_submission_batch.errors.add(:base, e.message)
        render :new
      end
    end
  end
end
