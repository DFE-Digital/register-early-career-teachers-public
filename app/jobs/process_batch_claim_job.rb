class ProcessBatchClaimJob < ApplicationJob
  # @param pending_induction_submission_batch [PendingInductionSubmissionBatch]
  # @param author_email [String]
  # @param author_name [String]
  def perform(pending_induction_submission_batch, author_email, author_name)
    return if pending_induction_submission_batch.processing?
    return unless pending_induction_submission_batch.pending?

    pending_induction_submission_batch.processing!

    AppropriateBodies::ProcessBatch::Claim.new(
      pending_induction_submission_batch:,
      author: author_session(pending_induction_submission_batch, author_email, author_name)
    ).process!

    # First transition to processed so user sees the summary
    pending_induction_submission_batch.processed!

    # Then immediately transition to completed for claims
    pending_induction_submission_batch.completed!
  rescue StandardError => e
    Rails.logger.debug("Attempt #{executions}: #{e.message}")

    pending_induction_submission_batch.update!(error_message: e.message)
    pending_induction_submission_batch.failed!

    raise
  end

private

  def author_session(pending_induction_submission_batch, author_email, author_name)
    Sessions::Users::AppropriateBodyPersona.new(
      email: author_email,
      name: author_name,
      appropriate_body_id: pending_induction_submission_batch.appropriate_body.id
    )
  end
end
