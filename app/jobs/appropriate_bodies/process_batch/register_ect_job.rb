module AppropriateBodies
  module ProcessBatch
    # @see AppropriateBodies::ProcessBatch::Claim
    class RegisterECTJob < ApplicationJob
      queue_as :process_batch

      before_enqueue :check_for_ongoing_induction_period

      def perform(pending_induction_submission_id, author_email, author_name)
        pending_induction_submission = PendingInductionSubmission.find(pending_induction_submission_id)
        pending_induction_submission_batch = pending_induction_submission.pending_induction_submission_batch
        appropriate_body_period = pending_induction_submission_batch.appropriate_body_period

        author = Events::AppropriateBodyBatchAuthor.new(
          email: author_email,
          name: author_name,
          appropriate_body_period_id: appropriate_body_period.id,
          batch_id: pending_induction_submission_batch.id
        )

        # OPTIMIZE: params effectively passed in twice
        ClaimAnECT::RegisterECT.new(
          appropriate_body_period:,
          pending_induction_submission:,
          author:
        ).register(
          started_on: pending_induction_submission.started_on,
          induction_programme: pending_induction_submission.induction_programme,
          training_programme: pending_induction_submission.training_programme
        )
      end

    private

      def check_for_ongoing_induction_period
        trn = PendingInductionSubmission.find(arguments.first).trn
        teacher = Teacher.find_by(trn:)

        throw :abort if teacher&.ongoing_induction_period.present?
      end
    end
  end
end
