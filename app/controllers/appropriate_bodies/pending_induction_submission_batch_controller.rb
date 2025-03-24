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

    class InvalidHeaders < StandardError; end
    class DuplicateTRNs < StandardError; end
    class MissingTRNs < StandardError; end

    # OPTIMIZE: CreatePendingInductionSubmissionBatch service
    #
    # TRNs are essential, tabular data with duplicate or missing TRNs will not be processed
    # HEADERs must conform, tabular data that does not use the template will be rejected
    # 'error' is an optional/additional column only seen when partially processed data is reuploaded
    #
    def create
      @pending_induction_submission_batch = PendingInductionSubmissionBatch.new(appropriate_body: @appropriate_body, **import_params)

      if @pending_induction_submission_batch.save!
        raise InvalidHeaders unless @pending_induction_submission_batch.has_valid_csv_headings?
        raise MissingTRNs unless @pending_induction_submission_batch.has_essential_csv_cells?
        raise DuplicateTRNs unless @pending_induction_submission_batch.has_unique_trns?

        ImportJob.perform_later(@pending_induction_submission_batch)

        redirect_to ab_import_path(@pending_induction_submission_batch), alert: 'File uploaded'
      else
        render :new
      end
    rescue InvalidHeaders
      @pending_induction_submission_batch.errors.add(:csv_file, "CSV file uses wrong headers")
      render :new
    rescue DuplicateTRNs
      @pending_induction_submission_batch.errors.add(:csv_file, "CSV file contains duplicate TRNs")
      render :new
    rescue MissingTRNs
      @pending_induction_submission_batch.errors.add(:csv_file, "CSV file contains missing TRNs")
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
