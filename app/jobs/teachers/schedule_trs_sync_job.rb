module Teachers
  class ScheduleTRSSyncJob < RecurringJob
    queue_as :default

    BATCH_SIZE = 50

    def perform
      teachers =
        Teacher
          .with_trn
          .syncable_with_trs
          .ordered_by_trs_data_last_refreshed_at_nulls_first
          .limit(BATCH_SIZE)

      teachers.each_with_index do |teacher, i|
        Teachers::SyncTeacherWithTRSJob.set(wait: i.seconds).perform_later(teacher:)
      end
    end
  end
end
