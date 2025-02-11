class PassECTInductionJob < ApplicationJob
  def perform(trn:, completed_date:, pending_induction_submission_id:)
    ActiveRecord::Base.transaction do
      api_client.pass_induction!(trn:, completed_date:)

      PendingInductionSubmission.find(pending_induction_submission_id).update!(delete_at: 24.hours.from_now)
    end
  end

private

  def api_client
    TRS::APIClient.new
  end
end
