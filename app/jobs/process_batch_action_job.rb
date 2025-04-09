class ProcessBatchActionJob < ApplicationJob
  retry_on StandardError, attempts: 3

  # @param pending_induction_submission_batch [PendingInductionSubmissionBatch]
  # @param author_email [String]
  # @param author_name [String]
  def perform(pending_induction_submission_batch, author_email, author_name)
    if pending_induction_submission_batch.processing?
      # still processing
    elsif pending_induction_submission_batch.processed?

      batch_action(pending_induction_submission_batch, author_email, author_name).do!
      pending_induction_submission_batch.completed!

    elsif pending_induction_submission_batch.pending?
      pending_induction_submission_batch.processing!
      batch_action(pending_induction_submission_batch, author_email, author_name).process!
      pending_induction_submission_batch.processed!
    end
  rescue StandardError => e
    Rails.logger.debug("Attempt #{executions}: #{e.message}")

    pending_induction_submission_batch.update!(error_message: e.message)
    pending_induction_submission_batch.failed!

    raise
  end

private

  def batch_action(pending_induction_submission_batch, author_email, author_name)
    AppropriateBodies::ProcessBatch::Action.new(
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
