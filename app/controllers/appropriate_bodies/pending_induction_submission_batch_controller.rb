module AppropriateBodies
  class PendingInductionSubmissionBatchController < AppropriateBodiesController
    layout 'full'

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

  private

    def import_params
      params.require(:pending_induction_submission_batch).permit(:csv_file)
    end
  end
end
