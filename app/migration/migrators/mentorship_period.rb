module Migrators
  class MentorshipPeriod < Migrators::Base
    def self.record_count
      ects.count
    end

    def self.model
      :mentorship_period
    end

    def self.ects
      ::Migration::ParticipantProfile.ect
        .where(id: Migration::InductionRecord.group(:participant_profile_id).having("count(participant_profile_id) = 1").count.keys)
        .distinct
    end

    def self.dependencies
      %i[teacher]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::MentorshipPeriod.connection.execute("TRUNCATE #{::MentorshipPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.ects.eager_load(:teacher_profile)) do |participant_profile|
        migrate_one!(participant_profile)
      end
    end

    def migrate_one!(participant_profile)
      teacher = find_teacher_by_trn!(participant_profile.teacher_profile.trn)

      success = true
      induction_records = InductionRecordSanitizer.new(participant_profile:)

      if induction_records.valid?
        mentorship_period_data = MentorshipPeriodExtractor.new(induction_records:)
        success = Builders::MentorshipPeriods.new(teacher:, mentorship_period_data:).build
      else
        ::TeacherMigrationFailure.create!(teacher:,
                                          model: :mentorship_period,
                                          message: induction_records.error,
                                          migration_item_id: participant_profile.id,
                                          migration_item_type: participant_profile.class.name)
        success = false
      end

      success
    end

  private

    def preload_caches
      cache_manager.cache_teachers
    end
  end
end
