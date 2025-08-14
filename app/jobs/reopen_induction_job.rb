class ReopenInductionJob < ApplicationJob
  include TRS::RetryableClient

  def perform(trn:, start_date:)
    teacher = Teacher.find_by!(trn:)

    api_client.reopen_teacher_induction!(trn:, start_date:)

    Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
  end
end
