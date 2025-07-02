module AppropriateBodies
  module ProcessBatch
    class ActionsController < PendingInductionSubmissionBatchController
      def index
        @pending_induction_submission_batches = PendingInductionSubmissionBatch
            .for_appropriate_body(@appropriate_body)
            .action
            .order(id: :desc)
      end

      def create
        @pending_induction_submission_batch = new_batch_action

        if csv_data.valid?
          @pending_induction_submission_batch.update!(data: csv_data.to_a, **csv_data.metadata)

          record_bulk_upload_started_event
          process_batch_action

          redirect_to ab_batch_action_path(@pending_induction_submission_batch)
        else
          csv_data.errors.each do |error|
            @pending_induction_submission_batch.errors.add(error.attribute, error.message)
          end

          render :new, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing
        @pending_induction_submission_batch.errors.add(:csv_file, 'Select a file')
        render :new, status: :unprocessable_entity
      end

      def edit
        redirect_to ab_batch_action_path(@pending_induction_submission_batch) unless @pending_induction_submission_batch.processed?
      end

      def update
        @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

        process_batch_action
        record_bulk_upload_completed_event

        redirect_to ab_batch_action_path(@pending_induction_submission_batch)
      end

    private

      def new_batch_action
        PendingInductionSubmissionBatch.new_action_for(appropriate_body: @appropriate_body, author: current_user)
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
