class PassECTInductionJob < ApplicationJob
  # @param trn [String]
  # @param start_date [Date]
  # @param completed_date [Date]
  def perform(trn:, start_date:, completed_date:, use_fake_trs_api: false)
    Current.set(use_fake_trs_api:) do
      teacher = Teacher.find_by!(trn:)

      api_client = TRS::APIClient.build
      api_client.pass_induction!(trn:, start_date:, completed_date:)

      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
