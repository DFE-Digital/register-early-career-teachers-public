module Teachers
  class SyncTeacherWithTRSJob < ApplicationJob
    include TRS::RetryableClient

    queue_as :trs_sync

    def perform(teacher:)
      Teachers::RefreshTRSAttributes.new(teacher, api_client:).refresh!
    end
  end
end
