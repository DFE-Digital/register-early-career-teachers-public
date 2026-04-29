module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    include TRS::RetryableClient

    queue_as :trs_sync

    # param teacher [Teacher]
    def perform(teacher:)
      return if teacher.trnless? || teacher.trs_deactivated? || teacher.trs_not_found?

      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
