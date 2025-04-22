module AppropriateBodies
  class PendingInductionSubmissionBatchController < AppropriateBodiesController
    layout 'full'

    def show
      pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])
      @pending_induction_submission_batch = PendingInductionSubmissionBatchPresenter.new(pending_induction_submission_batch)

      if wrong_appropriate_body?
        render_unauthorised
      else
        respond_to do |format|
          format.html
          format.csv do
            send_data @pending_induction_submission_batch.to_csv,
                      filename: "#{@appropriate_body.name}.csv",
                      type: 'text/csv'
          end
        end
      end
    end

    def edit
      pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])
      @pending_induction_submission_batch = PendingInductionSubmissionBatchPresenter.new(pending_induction_submission_batch)

      render_unauthorised if wrong_appropriate_body?
    end

    def new
      pending_induction_submission_batch = PendingInductionSubmissionBatch.new
      @pending_induction_submission_batch = PendingInductionSubmissionBatchPresenter.new(pending_induction_submission_batch)
    end

  private

    def import_params
      params.require(:pending_induction_submission_batch).permit(:csv_file)
    end

    def csv_data
      @csv_data ||= ProcessBatchForm.from_uploaded_file(
        headers: @pending_induction_submission_batch.column_headers,
        csv_file: import_params[:csv_file]
      )
    end

    def wrong_appropriate_body?
      current_user.appropriate_body_id != @pending_induction_submission_batch.appropriate_body.id
    end

    def render_unauthorised
      render "errors/unauthorised", status: :unauthorized
    end
  end
end
