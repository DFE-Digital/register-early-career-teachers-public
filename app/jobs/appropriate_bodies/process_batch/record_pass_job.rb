module AppropriateBodies
  module ProcessBatch
    # @see AppropriateBodies::ProcessBatch::Action
    class RecordPassJob < ApplicationJob
      queue_as :process_batch

      def perform(pending_induction_submission_id, author_email, author_name)
        pending_induction_submission = PendingInductionSubmission.find(pending_induction_submission_id)
        pending_induction_submission_batch = pending_induction_submission.pending_induction_submission_batch
        appropriate_body = pending_induction_submission_batch.appropriate_body

        author = Events::AppropriateBodyBatchAuthor.new(
          email: author_email,
          name: author_name,
          appropriate_body_id: appropriate_body.id,
          batch_id: pending_induction_submission_batch.id
        )

        RecordPass.new(
          appropriate_body:,
          pending_induction_submission:,
          author:
        ).pass!
      end
    end
  end
end
