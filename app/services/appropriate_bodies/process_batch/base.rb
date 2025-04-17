module AppropriateBodies
  module ProcessBatch
    class Base
      attr_reader :row,
                  :pending_induction_submission_batch,
                  :pending_induction_submission,
                  :appropriate_body,
                  :author

      def initialize(pending_induction_submission_batch:, author:)
        @pending_induction_submission_batch = pending_induction_submission_batch
        @author = author
        @appropriate_body = pending_induction_submission_batch.appropriate_body
      end

    private

      # @return [PendingInductionSubmission]
      def sparse_pending_induction_submission
        ::PendingInductionSubmission.create(
          pending_induction_submission_batch:,
          appropriate_body:,
          trn: row.trn,
          date_of_birth: Date.iso8601(row.dob)
        )
      end

      # @param message [String]
      # @return [Boolean]
      def capture_error(message)
        pending_induction_submission.update(error_message: message)
      end
    end
  end
end
