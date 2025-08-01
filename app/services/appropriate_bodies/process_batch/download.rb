module AppropriateBodies
  module ProcessBatch
    class Download
      class MissingCSVDataError < StandardError; end

      attr_reader :pending_induction_submission_batch

      def initialize(pending_induction_submission_batch:)
        @pending_induction_submission_batch = pending_induction_submission_batch
      end

      # @return [String]
      def filename
        "Errors for #{pending_induction_submission_batch.file_name}"
      end

      # @return [String]
      def type
        'text/csv'
      end

      # @raise [AppropriateBodies::ProcessBatch::Download::MissingCSVDataError]
      # @return [String]
      def to_csv
        raise MissingCSVDataError, "No persisted CSV data found" if pending_induction_submission_batch.data.blank?

        CSV.generate(headers:, write_headers: true, force_quotes: true) do |csv|
          errored_rows.each { |row| csv << row }
        end
      end

    private

      # @return [Array<String>]
      def headers
        pending_induction_submission_batch.row_headings.values
      end

      # @return [Hash{String => Array<String>}]
      def failed_submissions
        @failed_submissions ||= pending_induction_submission_batch.pending_induction_submissions.with_errors.pluck(:trn, :error_messages).to_h
      end

      # @return [Array<Array>]
      def errored_rows
        pending_induction_submission_batch.rows.filter_map do |row|
          errors = failed_submissions[row.sanitised_trn]
          row.with_errors(errors) if errors.present?
        end
      end
    end
  end
end
