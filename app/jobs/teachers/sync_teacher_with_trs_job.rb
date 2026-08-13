module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    include TRS::RetryableClient

    queue_as :trs_sync

    # @param teacher [Teacher]
    def perform(teacher:)
      return if teacher.trnless? || !teacher.syncable_with_trs?

      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
