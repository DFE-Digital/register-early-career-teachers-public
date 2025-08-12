class ReopenInductionJob < ApplicationJob
  include TRS::RetryableClient

  def perform(trn:, start_date:)
    api_client.reopen_teacher_induction!(trn:, start_date:)
  end
end
