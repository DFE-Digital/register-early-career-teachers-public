module Migrators
  class TrainingPeriod < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :training_period
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect_or_mentor).where.not(trn: nil).distinct
    end

    def self.dependencies
      %i[ect_at_school_period mentor_at_school_period school_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::TrainingPeriod.connection.execute("TRUNCATE #{::TrainingPeriod.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        migrate_one!(teacher_profile)
      end
    end

    def migrate_one!(teacher_profile)
      teacher = find_teacher_by_trn!(teacher_profile.trn)

      result = true

      teacher_profile
        .participant_profiles
        .ect_or_mentor
        .eager_load(induction_records: [induction_programme: [school_cohort: :school]])
        .find_each do |participant_profile|
          sanitizer = InductionRecordSanitizer.new(participant_profile:, group_by: :school)

          if sanitizer.valid?
            sanitizer.induction_records.each_value do |induction_records_group|
              next if result == false

              training_period_data = TrainingPeriodExtractor.new(induction_records: induction_records_group).training_periods

              result = if participant_profile.ect?
                         Builders::ECT::TrainingPeriods.new(teacher:, training_period_data:).build
                       else
                         Builders::Mentor::TrainingPeriods.new(teacher:, training_period_data:).build
                       end
            end

          else
            ::TeacherMigrationFailure.create!(teacher:,
                                              model: :training_period,
                                              message: sanitizer.error,
                                              migration_item_id: participant_profile.id,
                                              migration_item_type: participant_profile.class.name)
            result = false
          end
        end

      result
    end

  private

    def preload_caches
      cache_manager.cache_teachers
      cache_manager.cache_schools
      cache_manager.cache_lead_providers
      cache_manager.cache_active_lead_providers
      cache_manager.cache_delivery_partners
      cache_manager.cache_school_partnerships
      cache_manager.cache_lead_provider_delivery_partnerships
    end
  end
end
