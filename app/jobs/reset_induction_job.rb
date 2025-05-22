class ResetInductionJob < ApplicationJob
  def perform(trn:)
    api_client.reset_teacher_induction(trn:)
  end

private

  def api_client
    TRS::APIClient.build
  end
end
