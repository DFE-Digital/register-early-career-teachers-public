module AppropriateBodies
  class PendingInductionSubmissionBatchController < AppropriateBodiesController
    layout 'full'

    before_action :find_batch, only: %i[show edit]

    def show
      respond_to do |format|
        format.html

        format.csv do
          send_data download.to_csv, filename: download.filename, type: download.type
        end
      end
    end

    def edit
      # no-op
    end

    def new
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new
    end

  private

    def import_params
      params.require(:pending_induction_submission_batch).permit(:csv_file)
    end

    def csv_data
      @csv_data ||= ProcessBatchForm.from_uploaded_file(
        headers: @pending_induction_submission_batch.row_headings,
        csv_file: import_params[:csv_file]
      )
    end

    def wrong_appropriate_body?
      current_user.appropriate_body_id != @pending_induction_submission_batch.appropriate_body.id
    end

    def find_batch
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

      render "errors/unauthorised", status: :unauthorized if wrong_appropriate_body?
    end

    def record_bulk_upload_started_event
      Events::Record.record_bulk_upload_started_event!(
        author: current_user,
        batch: @pending_induction_submission_batch
      )
    end

    def record_bulk_upload_completed_event
      Events::Record.record_bulk_upload_completed_event!(
        author: current_user,
        batch: @pending_induction_submission_batch
      )
    end

    def download
      @download ||= ProcessBatch::Download.new(pending_induction_submission_batch: @pending_induction_submission_batch)
    end
  end
end
