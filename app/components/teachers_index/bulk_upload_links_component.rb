class TeachersIndex::BulkUploadLinksComponent < ViewComponent::Base
  include GovukLinkHelper
  include Rails.application.routes.url_helpers

  def initialize(appropriate_body:)
    @appropriate_body = appropriate_body
  end

private

  attr_reader :appropriate_body

  def bulk_upload_enabled?
    Rails.application.config.enable_bulk_upload
  end

  def bulk_claim_enabled?
    Rails.application.config.enable_bulk_claim
  end

  def batch_action_path
    if has_existing_bulk_uploads?
      ab_batch_actions_path
    else
      new_ab_batch_action_path
    end
  end

  def has_existing_bulk_uploads?
    PendingInductionSubmissionBatch
      .for_appropriate_body(appropriate_body)
      .action
      .exists?
  end
end
