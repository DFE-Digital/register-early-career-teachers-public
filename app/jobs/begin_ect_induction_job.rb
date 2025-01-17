class BeginECTInductionJob < ApplicationJob
  def perform(trn:, start_date:, teacher_id:, pending_induction_submission_id: nil)
    ActiveRecord::Base.transaction do
      api_client.begin_induction!(trn:, start_date:)

      Teacher.find(teacher_id).update!(induction_start_date_submitted_to_trs_at: Time.zone.now)

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
