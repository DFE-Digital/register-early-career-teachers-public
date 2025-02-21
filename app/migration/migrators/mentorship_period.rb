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
      migrate(self.class.ects) do |participant_profile|
        safe_migrate_mentorships(participant_profile:)
      end
    end

    def safe_migrate_mentorships(participant_profile:)
      teacher = ::Teacher.find_by(ecf_ect_profile_id: participant_profile.id)

      if teacher.nil?
        failure_manager.record_failure(participant_profile, "Cannot find Teacher for ECT in mentorship period")
        return false
      end

      success = true
      induction_records = InductionRecordSanitizer.new(participant_profile:)

      if induction_records.valid?
        mentorship_period_data = MentorshipPeriodExtractor.new(induction_records:)
        success = Builders::MentorshipPeriods.new(teacher:, mentorship_period_data:).build
      else
        ::TeacherMigrationFailure.create!(teacher:, message: induction_records.error, migration_item_id: participant_profile.id,
                                          migration_item_type: participant_profile.class.name)
        success = false
      end

      success
    end
  end
end
