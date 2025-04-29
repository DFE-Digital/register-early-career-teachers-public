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
        @pending_induction_submission_batch = new_batch_action

        if csv_data.valid?
          @pending_induction_submission_batch.data = csv_data.to_a
          @pending_induction_submission_batch.save!

          process_batch_action

          redirect_to ab_batch_action_path(@pending_induction_submission_batch), alert: 'File processing'
        else
          @pending_induction_submission_batch = csv_data
          render :new, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing
        @pending_induction_submission_batch.errors.add(:csv_file, "Attach a CSV file")
        render :new, status: :unprocessable_entity
      rescue StandardError => e
        @pending_induction_submission_batch.errors.add(:base, e.message)
        render :new, status: :unprocessable_entity
      end

      def update
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

        process_batch_action

        redirect_to ab_batch_action_path(@pending_induction_submission_batch), alert: 'Induction changes actioned'
      end

    private

      def new_batch_action
        PendingInductionSubmissionBatch.new_action_for(appropriate_body: @appropriate_body)
      end

      def process_batch_action
        ProcessBatchActionJob.perform_later(
          @pending_induction_submission_batch,
          current_user.email,
          current_user.name
        )
      end
    end
  end
end
