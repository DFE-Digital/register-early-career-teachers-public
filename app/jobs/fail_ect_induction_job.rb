class FailECTInductionJob < ApplicationJob
  include TRS::RetryableClient

  def perform(trn:, start_date:, completed_date:)
    ActiveRecord::Base.transaction do
      api_client.fail_induction!(trn:, start_date:, completed_date:)
      teacher = Teacher.find_by!(trn:)
      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
