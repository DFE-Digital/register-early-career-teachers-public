class PassECTInductionJob < ApplicationJob
  def perform(trn:, start_date:, completed_date:, pending_induction_submission_id:)
    ActiveRecord::Base.transaction do
      api_client.pass_induction!(trn:, start_date:, completed_date:)

      PendingInductionSubmission.find(pending_induction_submission_id).update!(delete_at: 24.hours.from_now)

      Teachers::RefreshTRSAttributes.new(Teacher.find_by!(trn:)).refresh!
    end
  end

private

  def api_client
    TRS::APIClient.new
  end
end
