class ResetInductionJob < ApplicationJob
  def perform(trn:)
    api_client = TRS::APIClient.build
    api_client.reset_teacher_induction!(trn:)
  end
end
