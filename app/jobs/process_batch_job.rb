# Run batch process services
class ProcessBatchJob < ApplicationJob
  # @see [AppropriateBodies::ProcessBatch::Claim, AppropriateBodies::ProcessBatch::Action]
  def self.batch_service
    raise NotImplementedError, "You must implement the #{name}#batch_service method"
  end

  queue_as :process_batch

  retry_on ::RuntimeError, wait: 1.second, attempts: 2

  # @param pending_induction_submission_batch [PendingInductionSubmissionBatch]
  # @param author_email [String]
  # @param author_name [String]
  def perform(pending_induction_submission_batch, author_email, author_name)
    return if pending_induction_submission_batch.failed?

    author = event_author(pending_induction_submission_batch, author_email, author_name)
    batch_service = self.class.batch_service.new(pending_induction_submission_batch:, author:)

    batch_service.complete! if pending_induction_submission_batch.processed? || pending_induction_submission_batch.completing?
    batch_service.process! if pending_induction_submission_batch.pending? || pending_induction_submission_batch.processing?
  rescue StandardError => e
    Rails.logger.debug("Attempt #{executions}: #{e.message}")

    pending_induction_submission_batch.update!(error_message: e.message)
    pending_induction_submission_batch.failed!
    Sentry.capture_exception(e)
  end

private

  # @param pending_induction_submission_batch [PendingInductionSubmissionBatch]
  # @param email [String]
  # @param name [String]
  # @return [Events::AppropriateBodyBatchAuthor]
  def event_author(pending_induction_submission_batch, email, name)
    Events::AppropriateBodyBatchAuthor.new(
      email:,
      name:,
      appropriate_body_id: pending_induction_submission_batch.appropriate_body.id,
      batch_id: pending_induction_submission_batch.id
    )
  end
end
