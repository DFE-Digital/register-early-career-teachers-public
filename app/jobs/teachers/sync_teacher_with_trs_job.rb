module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    queue_as :trs_sync

    # @param teacher [Teacher]
    def perform(teacher:)
      return if teacher.trnless? || !teacher.syncable_with_trs?

      api_client = TRS::APIClient.build
      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
