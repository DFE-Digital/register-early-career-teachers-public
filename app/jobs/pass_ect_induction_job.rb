class PassECTInductionJob < ApplicationJob
  include TRS::RetryableClient

  def perform(trn:, start_date:, completed_date:, pending_induction_submission_id:)
    ActiveRecord::Base.transaction do
      api_client.pass_induction!(trn:, start_date:, completed_date:)

      PendingInductionSubmission.find(pending_induction_submission_id).update!(delete_at: 24.hours.from_now)

      teacher = Teacher.find_by!(trn:)
      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
