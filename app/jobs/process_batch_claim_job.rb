class ProcessBatchClaimJob < ApplicationJob
  # @param pending_induction_submission_batch [PendingInductionSubmissionBatch]
  # @param author_email [String]
  # @param author_name [String]
  def perform(pending_induction_submission_batch, author_email, author_name)
    return if pending_induction_submission_batch.processing?

    if pending_induction_submission_batch.processed?
      # change status first for quick response
      pending_induction_submission_batch.completed!
      batch_claim(pending_induction_submission_batch, author_email, author_name).do!

    elsif pending_induction_submission_batch.pending?
      pending_induction_submission_batch.processing!
      batch_claim(pending_induction_submission_batch, author_email, author_name).process!
      pending_induction_submission_batch.processed!
    end
  rescue StandardError => e
    Rails.logger.debug("Attempt #{executions}: #{e.message}")

    pending_induction_submission_batch.update!(error_message: e.message)
    pending_induction_submission_batch.failed!
  end

private

  def batch_claim(pending_induction_submission_batch, author_email, author_name)
    AppropriateBodies::ProcessBatch::Claim.new(
      pending_induction_submission_batch:,
      author: author_session(pending_induction_submission_batch, author_email, author_name)
    )
  end

  def author_session(pending_induction_submission_batch, author_email, author_name)
    Sessions::Users::AppropriateBodyPersona.new(
      email: author_email,
      name: author_name,
      appropriate_body_id: pending_induction_submission_batch.appropriate_body.id
    )
  end
end
