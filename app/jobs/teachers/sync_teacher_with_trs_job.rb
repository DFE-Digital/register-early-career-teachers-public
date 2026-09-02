module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    queue_as :trs_sync

    retry_on ActiveRecord::RecordInvalid, attempts: 1

    # @param teacher [Teacher]
    def perform(teacher:)
      return if teacher.trnless? || !teacher.syncable_with_trs?

      api_client = TRS::APIClient.build
      status = Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!

      Teachers::ReplaceTRN.new(teacher:).replace! if status == :teacher_merged
    end
  end
end
