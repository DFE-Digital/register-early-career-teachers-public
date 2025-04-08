module AppropriateBodies
  module ProcessBatch
    class ActionsController < PendingInductionSubmissionBatchController
      def index
        @pending_induction_submission_batches = PendingInductionSubmissionBatch
            .for_appropriate_body(@appropriate_body)
            .action
            .order(id: :desc)
            .select(:id, :batch_type, :batch_status, :error_message)
            .map { |b| b.attributes.values.map(&:to_s) }
      end

      def create
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.new_action_for(appropriate_body: @appropriate_body, **import_params)

        if @pending_induction_submission_batch.save! && @pending_induction_submission_batch.save(context: :uploaded)
          run_job

          redirect_to ab_batch_action_path(@pending_induction_submission_batch), alert: 'File processing'
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

      def update
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

        run_job

        redirect_to ab_batch_action_path(@pending_induction_submission_batch), alert: 'Induction changes actioned'
      end

    private

      def run_job
        ProcessBatchActionJob.perform_later(
          @pending_induction_submission_batch,
          current_user.email,
          current_user.name
        )
      end
    end
  end
end
