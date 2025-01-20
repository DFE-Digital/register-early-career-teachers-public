class FailECTInductionJob < ApplicationJob
  def perform(trn:, completion_date:, pending_induction_submission_id:)
    ActiveRecord::Base.transaction do
      api_client.fail_induction!(trn:, completion_date:)

      PendingInductionSubmission.find(pending_induction_submission_id).destroy!
    end
  end

private

  def api_client
    TRS::APIClient.new
  end
end
