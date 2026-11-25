class ResetInductionJob < ApplicationJob
  def perform(trn:, use_fake_trs_api: false)
    Current.set(use_fake_trs_api:) do
      api_client = TRS::APIClient.build
      api_client.reset_teacher_induction!(trn:)
    end
  end
end
