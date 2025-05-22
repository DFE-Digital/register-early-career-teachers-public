class FailECTInductionJob < ApplicationJob
  def perform(trn:, start_date:, completed_date:, pending_induction_submission_id: nil)
    ActiveRecord::Base.transaction do
      api_client.fail_induction!(trn:, start_date:, completed_date:)

      if pending_induction_submission_id.present?
        PendingInductionSubmission.find(pending_induction_submission_id).update!(delete_at: 24.hours.from_now)
      end

      Teachers::RefreshTRSAttributes.new(Teacher.find_by!(trn:)).refresh!
    end
  end

private

  def api_client
    TRS::APIClient.build
  end
end
