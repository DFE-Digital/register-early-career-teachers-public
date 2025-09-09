class TeachersIndex::BulkUploadLinksComponent < ApplicationComponent
  include Rails.application.routes.url_helpers

  def initialize(appropriate_body:)
    @appropriate_body = appropriate_body
  end

private

  attr_reader :appropriate_body

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
