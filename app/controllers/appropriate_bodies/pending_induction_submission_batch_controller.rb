module AppropriateBodies
  class PendingInductionSubmissionBatchController < AppropriateBodiesController
    layout 'full'

    def index
      @pending_induction_submission_batches =
        PendingInductionSubmissionBatch
          .where(appropriate_body: @appropriate_body)
          .order(:id)
          .select(:id, :status, :error_message)
          .map { |b| b.attributes.values.map(&:to_s) }
    end

    def show
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

      respond_to do |format|
        format.html
        format.csv do
          send_data @pending_induction_submission_batch.to_csv,
                    filename: "#{@appropriate_body.name}.csv",
                    type: 'text/csv'
        end
      end
    end

    def new
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new
    end

    def create
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new(appropriate_body: @appropriate_body, **import_params)

      if @pending_induction_submission_batch.save! && @pending_induction_submission_batch.save(context: :uploaded)
        ImportJob.perform_later(@pending_induction_submission_batch, current_user.email, current_user.name)

        redirect_to ab_import_path(@pending_induction_submission_batch), alert: 'File uploaded'
      else
        render :new
      end
    rescue ActionController::ParameterMissing, ActiveStorage::FileNotFoundError
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new
      @pending_induction_submission_batch.errors.add(:csv_file, "Attach a CSV file")
      render :new
    rescue StandardError => e
      @pending_induction_submission_batch.errors.add(:base, e.message)
      render :new
    end

  private

    def import_params
      params.require(:pending_induction_submission_batch).permit(:csv_file)
    end
  end
end
