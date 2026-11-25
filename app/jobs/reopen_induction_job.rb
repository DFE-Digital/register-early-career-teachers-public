class ReopenInductionJob < ApplicationJob
  def perform(trn:, start_date:, use_fake_trs_api: false)
    Current.set(use_fake_trs_api:) do
      teacher = Teacher.find_by!(trn:)

      api_client = TRS::APIClient.build
      api_client.reopen_teacher_induction!(trn:, start_date:)

      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
