module AppropriateBodies
  class PendingInductionSubmissionBatchController < AppropriateBodiesController
    layout 'full'

    # TODO: spec guard to prevent wrong appropriate body from accessing a batch
    def show
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

      if wrong_appropriate_body?
        block_other_ab
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
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.find(params[:id])

      block_other_ab if wrong_appropriate_body?
    end

    def new
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new
    end

  private

    def import_params
      params.require(:pending_induction_submission_batch).permit(:csv_file)
    end

    def wrong_appropriate_body?
      current_user.appropriate_body_id != @pending_induction_submission_batch.appropriate_body.id
    end

    def block_other_ab
      render "errors/unauthorised", status: :unauthorized
    end
  end
end
