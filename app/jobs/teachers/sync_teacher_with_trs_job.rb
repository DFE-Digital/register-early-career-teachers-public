module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    queue_as :trs_sync

    # @param teacher [Teacher]
    def perform(teacher:)
      return if teacher.trnless? || !teacher.syncable_with_trs?

      api_client = TRS::APIClient.build
      status = Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!

      return unless status == :teacher_merged

      Teachers::ReplaceTRN.new(teacher:).replace!
    end
  end
end
