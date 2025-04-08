module Teachers
  class ScheduleTRSSyncJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 1200

    def perform
      teachers = Teacher.order(trs_data_last_refreshed_at: :asc).limit(BATCH_SIZE)

      teachers.each_with_index do |teacher, i|
        Teachers::SyncTeacherWithTRSJob.set(wait: (i * 3).seconds).perform_later(teacher:)
      end
    end
  end
end
