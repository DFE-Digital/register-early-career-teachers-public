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
      induction_records = InductionRecordSanitizer.new(participant_profile:)

      mentorship_period_data = MentorshipPeriodExtractor.new(induction_records:)
      Builders::MentorshipPeriods.new(teacher:, mentorship_period_data:).build
    end

  private

    def preload_caches
      cache_manager.cache_teachers
    end
  end
end
