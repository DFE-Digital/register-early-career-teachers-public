class ReopenInductionJob < ApplicationJob
  def perform(trn:, start_date:)
    api_client.reopen_teacher_induction!(trn:, start_date:)
  end

private

  def api_client
    TRS::APIClient.build
  end
end
