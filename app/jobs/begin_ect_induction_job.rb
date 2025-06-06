class BeginECTInductionJob < ApplicationJob
  def perform(trn:, start_date:, pending_induction_submission_id: nil)
    ActiveRecord::Base.transaction do
      api_client.begin_induction!(trn:, start_date:)

      if pending_induction_submission_id.present?
        PendingInductionSubmission.find(pending_induction_submission_id).update!(delete_at: 24.hours.from_now)
      end
    end
  end

private

  def api_client
    TRS::APIClient.build
  end
end
