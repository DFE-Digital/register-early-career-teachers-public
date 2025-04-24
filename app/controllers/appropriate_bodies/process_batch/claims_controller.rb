module AppropriateBodies
  module ProcessBatch
    class ClaimsController < PendingInductionSubmissionBatchController
      def index
        @pending_induction_submission_batches = PendingInductionSubmissionBatch
            .for_appropriate_body(@appropriate_body)
            .claim
            .order(id: :desc)
            .select(:id, :batch_type, :batch_status, :error_message)
            .map { |b| b.attributes.values.map(&:to_s) }
      end

      def create
        @pending_induction_submission_batch = new_batch_claim

        if csv_data.valid?
          @pending_induction_submission_batch.data = csv_data.to_a
          @pending_induction_submission_batch.save!

          process_batch_claim

          redirect_to ab_batch_claim_path(@pending_induction_submission_batch), alert: 'File processing'
        else
          @pending_induction_submission_batch = csv_data
          render :new
        end
      rescue ActionController::ParameterMissing
        @pending_induction_submission_batch.errors.add(:csv_file, "Attach a CSV file")
        render :new
      rescue StandardError => e
        @pending_induction_submission_batch.errors.add(:base, e.message)
        render :new
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
