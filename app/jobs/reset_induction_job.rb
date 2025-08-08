class ResetInductionJob < ApplicationJob
  include TRS::RetryableClient

  def perform(trn:)
    api_client.reset_teacher_induction!(trn:)
  end
end
