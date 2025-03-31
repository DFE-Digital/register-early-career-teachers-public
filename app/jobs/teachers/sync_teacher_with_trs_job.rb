module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    queue_as :trs_sync

    def perform(teacher:)
      Teachers::RefreshTRSAttributes.new(teacher).refresh!
    end
  end
end
