module AppropriateBodies
  module ProcessBatch
    # @see AppropriateBodies::ProcessBatch::Action
    class RecordPassJob < ApplicationJob
      queue_as :process_batch

      def perform(pending_induction_submission_id, author_email, author_name)
        pending_induction_submission = PendingInductionSubmission.find(pending_induction_submission_id)
        batch = pending_induction_submission.pending_induction_submission_batch
        appropriate_body = batch.appropriate_body
        teacher = Teacher.find_by(trn: pending_induction_submission.trn)

        author = Events::AppropriateBodyBatchAuthor.new(
          email: author_email,
          name: author_name,
          appropriate_body_id: appropriate_body.id,
          batch_id: batch.id
        )

        record_pass = RecordPass.new(teacher:, appropriate_body:, author:)

        record_pass.call(
          finished_on: pending_induction_submission.finished_on,
          number_of_terms: pending_induction_submission.number_of_terms
        )

        pending_induction_submission.update!(delete_at: 24.hours.from_now)
      end
    end
  end
end
