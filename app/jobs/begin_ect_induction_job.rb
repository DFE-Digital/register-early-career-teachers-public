class BeginECTInductionJob < ApplicationJob
  def perform(trn:, start_date:, pending_induction_submission_id: nil)
    ActiveRecord::Base.transaction do
      api_client.begin_induction!(trn:, start_date:)

      if pending_induction_submission_id.present?
        PendingInductionSubmission.find(pending_induction_submission_id).destroy!
      end
    end
  end

private

  def api_client
    TRS::APIClient.new
  end
end
