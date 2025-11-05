class TeachersIndex::BulkUploadLinksComponent < ApplicationComponent
  include Rails.application.routes.url_helpers

  def initialize(appropriate_body_period:)
    @appropriate_body_period = appropriate_body_period
  end

private

  attr_reader :appropriate_body_period

  def batch_claim_path
    has_existing_batch_claims? ? ab_batch_claims_path : new_ab_batch_claim_path
  end

  def batch_action_path
    has_existing_batch_actions? ? ab_batch_actions_path : new_ab_batch_action_path
  end

  def has_existing_batch_actions?
    batches.action.any?
  end

  def has_existing_batch_claims?
    batches.claim.any?
  end

  def batches
    PendingInductionSubmissionBatch.for_appropriate_body_period(appropriate_body_period)
  end
end
