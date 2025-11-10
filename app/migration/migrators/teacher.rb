module Migrators
  class Teacher < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :teacher
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect_or_mentor).where.not(trn: nil).distinct
    end

    def self.dependencies
      %i[school_partnership]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Teacher.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        migrate_one!(teacher_profile)
      end
    end

    def migrate_one!(teacher_profile)
      teacher = migrate_teacher!(teacher_profile)
      result = true

      teacher_profile
        .participant_profiles
        .eager_load(induction_records: [schedule: :cohort,
                                        induction_programme: [
                                          partnership: %i[cohort lead_provider delivery_partner school],
                                          school_cohort: :school
                                        ]])
        .find_each do |participant_profile|
          sanitizer = ::InductionRecordSanitizer.new(participant_profile:)

          if sanitizer.valid?
            result = migrate_teacher_periods(teacher, sanitizer.induction_records)
          else
            ::TeacherMigrationFailure.create!(teacher:,
                                              model: participant_profile.ect? ? :ect_at_school_period : :mentor_at_school_period,
                                              message: sanitizer.error,
                                              migration_item_id: participant_profile.id,
                                              migration_item_type: participant_profile.class.name)
            result = false
          end
        end

      result ? teacher : result
    end

  private

    def migrate_teacher!(teacher_profile)
      teacher = ::Teacher.find_or_initialize_by(trn: teacher_profile.trn)
      user = teacher_profile.user

      if teacher.persisted? && name_does_not_match?(teacher, user.full_name)
        teacher.corrected_name = user.full_name
      else
        # FIXME: we should look these up in TRS but this will hammer it
        parser = Teachers::FullNameParser.new(full_name: user.full_name)
        teacher.trs_first_name = parser.first_name
        teacher.trs_last_name = parser.last_name
      end

      teacher.api_id = user.id
      teacher.created_at = user.created_at
      teacher.updated_at = user.updated_at
      teacher.save!

      teacher
    end

    def build_teacher_periods(teacher, teacher_periods, participant_profile)
      success = true
      is_an_ect = participant_profile.ect?
      school_period_class = is_an_ect ? ::ECTAtSchoolPeriod : ::MentorAtSchoolPeriod

      teacher_periods.each_with_index do |period, idx|
        school = find_school_by_urn!(period.urn)

        school_period = school_period_class.find_or_initialize_by(teacher:, school:, started_on: period.start_date)
        school_period.ecf_start_induction_record_id = period.start_source_id
        # NOTE: we were using the start of the next period for the end_date where present
        school_period.finished_on = period.end_date
        school_period.ecf_end_induction_record_id = period.end_source_id

        school_period.created_at = participant_profile.created_at if idx.zero?
        school_period.save!

        period.training_periods.each do |training_record|
        
          training_period = ::TrainingPeriod.find_or_initialize_by(ecf_start_induction_record_id: training_record.start_source_id)
          training_period.training_programme = training_record.training_programme
          training_period.ect_at_school_period = school_period
          training_period.started_on = training_record.start_date
          training_period.finished_on = training_record.end_date
          training_period.ecf_end_induction_record_id = training_record.end_source_id
          training_period.school_partnership = if training_record.training_programme == "provider_led"
                                                 find_school_partnership!(training_record, school)
                                               end
          training_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:,
                                            model: :training_period,
                                            message: e.message,
                                            migration_item_id: training_record.start_source_id,
                                            migration_item_type: "Migration::InductionRecord")
          success = false
        end
      rescue ActiveRecord::ActiveRecordError => e
        ::TeacherMigrationFailure.create!(teacher:,
                                          model: is_an_ect ? :ect_at_school_period : :mentor_at_school_period,
                                          message: e.message,
                                          migration_item_id: period.start_source_id,
                                          migration_item_type: "Migration::InductionRecord")
        success = false
      end
      success
    end

    def migrate_teacher_periods(teacher, induction_records)
      participant_profile = induction_records.first.participant_profile
      teacher_periods = ::TeacherPeriodsExtractor.new(induction_records:).teacher_periods
      result = true

      payments_frozen_year = participant_profile.previous_payments_frozen_cohort_start_year

      if participant_profile.ect?
        teacher.ect_payments_frozen_year = payments_frozen_year if payments_frozen_year
        teacher.ect_pupil_premium_uplift = true if participant_profile.pupil_premium_uplift
        teacher.ect_sparsity_uplift = true if participant_profile.sparsity_uplift
        teacher.api_ect_training_record_id = participant_profile.id
        teacher.save!

        build_teacher_periods(teacher, teacher_periods, participant_profile)

        # result = Builders::ECT::SchoolPeriods
        #   .new(teacher:, school_periods:, created_at: participant_profile.created_at)
        #   .build

      else
        teacher.mentor_payments_frozen_year = payments_frozen_year if payments_frozen_year
        teacher.api_mentor_training_record_id = participant_profile.id
        teacher.save!

        build_teacher_periods(teacher, teacher_periods, participant_profile)

        # result = Builders::Mentor::SchoolPeriods
        #   .new(teacher:, school_periods:, created_at: participant_profile.created_at)
        #   .build
      end

      if result
        training_period_data = ::TrainingPeriodExtractor.new(induction_records:).training_periods

        result = if participant_profile.ect?
                   Builders::ECT::TrainingPeriods.new(teacher:, training_period_data:).build
                 else
                   Builders::Mentor::TrainingPeriods.new(teacher:, training_period_data:).build
                 end
      end

      result
    end

    def name_does_not_match?(teacher, full_name)
      [teacher.trs_first_name, teacher.trs_last_name].join(" ") != full_name
    end

    def find_school_by_urn!(urn)
      school = CacheManager.instance.find_school_by_urn(urn)
      raise(ActiveRecord::RecordNotFound, "Couldn't find School with URN: #{urn}") unless school

      school
    end

    def find_school_partnership!(training_period_data, school)
      lead_provider = CacheManager.instance.find_lead_provider_by_name(training_period_data.lead_provider)
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find LeadProvider with name #{training_period_data.lead_provider}") unless lead_provider

      active_lead_provider = CacheManager.instance.find_active_lead_provider(lead_provider_id: lead_provider.id, contract_period_year: training_period_data.cohort_year)
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find ActiveLeadProvider with lead_provider_id #{lead_provider.id} and contract_period_year #{training_period_data.cohort_year}") unless active_lead_provider

      delivery_partner = CacheManager.instance.find_delivery_partner_by_name(training_period_data.delivery_partner)
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find DeliveryPartner with name #{training_period_data.delivery_partner}") unless delivery_partner

      lead_provider_delivery_partnership = CacheManager.instance.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id: active_lead_provider.id, delivery_partner_id: delivery_partner.id)
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find LeadProviderDeliveryPartnership with active_lead_provider_id #{active_lead_provider.id} and delivery_partner_id #{delivery_partner.id}") unless lead_provider_delivery_partnership

      school_partnership = CacheManager.instance.find_school_partnership(lead_provider_delivery_partnership_id: lead_provider_delivery_partnership.id, school_id: school.id)
      raise(ActiveRecord::RecordNotFound,
            "Couldn't find SchoolPartnership with lead_provider_delivery_partnership_id #{lead_provider_delivery_partnership.id} and school_id #{school.id}") unless school_partnership

      school_partnership
    end

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
