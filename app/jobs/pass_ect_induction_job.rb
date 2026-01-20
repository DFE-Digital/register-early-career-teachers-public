class PassECTInductionJob < ApplicationJob
  include TRS::RetryableClient

  # @param trn [String]
  # @param start_date [Date]
  # @param completed_date [Date]
  def perform(trn:, start_date:, completed_date:)
    teacher = Teacher.find_by!(trn:)
    api_client.pass_induction!(trn:, start_date:, completed_date:)
    Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
  end
end
