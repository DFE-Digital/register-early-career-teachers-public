module Migrators
  class Teacher < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :teacher
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(::Migration::ParticipantProfile.ect_or_mentor).distinct
    end

    def self.dependencies
      %i[schedule school_partnership]
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

      teacher_profile
        .participant_profiles
        .eager_load(induction_records: [schedule: :cohort,
                                        induction_programme: [
                                          partnership: %i[cohort lead_provider delivery_partner school],
                                          school_cohort: :school
                                        ]])
        .find_each do |participant_profile|
          migrate_profile_periods(teacher, participant_profile)
        end

      teacher
    end

  private

    def migrate_teacher!(teacher_profile)
      teacher = ::Teacher.find_or_initialize_by(trn: teacher_profile.trn)
      user = teacher_profile.user

      if teacher_profile.trn.present?
        teacher = ::Teacher.find_or_initialize_by(trn: teacher_profile.trn)
        teacher.api_id = user.id
      else
        teacher = ::Teacher.find_or_initialize_by(api_id: user.id)
        teacher.trnless = true
      end

      if teacher.persisted? && name_does_not_match?(teacher, user.full_name)
        teacher.corrected_name = user.full_name
      else
        # FIXME: we should look these up in TRS but this will hammer it
        parser = Teachers::FullNameParser.new(full_name: user.full_name)
        teacher.trs_first_name = parser.first_name
        teacher.trs_last_name = parser.last_name
      end

      teacher.created_at = user.created_at
      teacher.updated_at = user.updated_at
      teacher.api_updated_at = calculate_api_updated_at(teacher_profile)
      teacher.save!

      teacher
    end

    def migrate_profile_periods(teacher, participant_profile)
      result = true
      sanitizer = ::InductionRecordSanitizer.new(participant_profile:)

      if sanitizer.valid?
        # TeacherPeriodsExtractor creates nested periods for a teacher with school periods at the top
        # |-school_period_1
        # |    |-training_period_1
        # |    |-training_period_2
        # |
        # |-school_period_2
        # |    |-training_period_3
        #
        teacher_periods = ::TeacherPeriodsExtractor.new(induction_records: sanitizer.induction_records).teacher_periods
        teacher_periods = add_mentor_at_multiple_school_periods_to(teacher_periods, participant_profile) if participant_profile.mentor?

        result = create_teacher_periods(teacher, teacher_periods, participant_profile)
        set_teacher_profile_values!(teacher, participant_profile)
      else
        ::TeacherMigrationFailure.create!(teacher:,
                                          model: participant_profile.ect? ? :ect_at_school_period : :mentor_at_school_period,
                                          message: sanitizer.error,
                                          migration_item_id: participant_profile.id,
                                          migration_item_type: participant_profile.class.name)
        result = false
      end

      result
    end

    def create_teacher_periods(teacher, teacher_periods, participant_profile)
      success = true
      school_period_class = participant_profile.ect? ? ::ECTAtSchoolPeriod : ::MentorAtSchoolPeriod

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
          next if participant_profile.mentor? && training_record.training_programme != "provider_led"

          training_period = ::TrainingPeriod.find_or_initialize_by(ecf_start_induction_record_id: training_record.start_source_id)
          training_period.training_programme = training_record.training_programme
          if participant_profile.ect?
            training_period.ect_at_school_period = school_period
          else
            training_period.mentor_at_school_period = school_period
          end
          training_period.started_on = training_record.start_date
          training_period.finished_on = training_record.end_date
          training_period.ecf_end_induction_record_id = training_record.end_source_id
          training_period.school_partnership = if training_record.training_programme == "provider_led"
                                                 find_school_partnership!(training_record, school)
                                               end
          training_period.schedule = find_schedule_for(training_record, participant_profile)
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
                                          model: participant_profile.ect? ? :ect_at_school_period : :mentor_at_school_period,
                                          message: e.message,
                                          migration_item_id: period.start_source_id,
                                          migration_item_type: "Migration::InductionRecord")
        success = false
      end

      success
    end

    def set_teacher_profile_values!(teacher, participant_profile)
      payments_frozen_year = participant_profile.previous_payments_frozen_cohort_start_year

      if participant_profile.ect?
        teacher.ect_payments_frozen_year = payments_frozen_year if payments_frozen_year
        teacher.ect_pupil_premium_uplift = true if participant_profile.pupil_premium_uplift
        teacher.ect_sparsity_uplift = true if participant_profile.sparsity_uplift
        teacher.api_ect_training_record_id = participant_profile.id
      else
        teacher.mentor_payments_frozen_year = payments_frozen_year if payments_frozen_year
        teacher.api_mentor_training_record_id = participant_profile.id
      end
      teacher.save!
    end

    def add_mentor_at_multiple_school_periods_to(teacher_periods, participant_profile)
      urns = teacher_periods.map(&:urn)
      participant_profile.school_mentors.eager_load(:school).find_each do |school_mentor|
        next if urns.include? school_mentor.school.urn

        teacher_periods << Migration::SchoolPeriod.new(urn: school_mentor.school.urn,
                                                       start_date: school_mentor.created_at.to_date,
                                                       end_date: nil,
                                                       start_source_id: school_mentor.id,
                                                       end_source_id: nil)
      end
      teacher_periods
    end

    def name_does_not_match?(teacher, full_name)
      [teacher.trs_first_name, teacher.trs_last_name].join(" ") != full_name
    end

    # Calculates the api_updated_at timestamp using ECF's ParticipantSerializer logic:
    # The max of participant_profiles.updated_at, user.updated_at,
    # participant_identities.updated_at, and induction_records.updated_at
    def calculate_api_updated_at(teacher_profile)
      user = teacher_profile.user
      participant_profiles = teacher_profile.participant_profiles.includes(:induction_records)
      participant_identities = user.participant_identities

      [
        participant_profiles.map(&:updated_at),
        user.updated_at,
        participant_identities.map(&:updated_at),
        participant_profiles.flat_map(&:induction_records).map(&:updated_at)
      ].flatten.compact.max
    end

    def find_school_by_urn!(urn)
      school = CacheManager.instance.find_school_by_urn(urn)
      raise(ActiveRecord::RecordNotFound, "Couldn't find School with URN: #{urn}") unless school

      school
    end

    def find_school_partnership!(training_period_data, school)
      lead_provider = CacheManager.instance.find_lead_provider_by_name(training_period_data.lead_provider)
      unless lead_provider
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find LeadProvider with name #{training_period_data.lead_provider}")
      end

      active_lead_provider = CacheManager.instance.find_active_lead_provider(lead_provider_id: lead_provider.id, contract_period_year: training_period_data.cohort_year)
      unless active_lead_provider
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find ActiveLeadProvider with lead_provider_id #{lead_provider.id} and contract_period_year #{training_period_data.cohort_year}")
      end

      delivery_partner = CacheManager.instance.find_delivery_partner_by_name(training_period_data.delivery_partner)
      unless delivery_partner
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find DeliveryPartner with name #{training_period_data.delivery_partner}")
      end

      lead_provider_delivery_partnership = CacheManager.instance.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id: active_lead_provider.id, delivery_partner_id: delivery_partner.id)
      unless lead_provider_delivery_partnership
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find LeadProviderDeliveryPartnership with active_lead_provider_id #{active_lead_provider.id} and delivery_partner_id #{delivery_partner.id}")
      end

      school_partnership = CacheManager.instance.find_school_partnership(lead_provider_delivery_partnership_id: lead_provider_delivery_partnership.id, school_id: school.id)
      unless school_partnership
        raise(ActiveRecord::RecordNotFound,
              "Couldn't find SchoolPartnership with lead_provider_delivery_partnership_id #{lead_provider_delivery_partnership.id} and school_id #{school.id}")
      end

      school_partnership
    end

    def find_schedule_for(training_period_data, participant_profile)
      return nil unless training_period_data.training_programme == "provider_led"
      return nil if training_period_data.schedule_identifier.blank?

      schedule = ::Schedule.find_by(
        identifier: training_period_data.schedule_identifier,
        contract_period_year: training_period_data.cohort_year
      )

      # ECTs cannot be assigned to replacement schedules
      return nil if schedule&.replacement_schedule? && participant_profile.ect?

      schedule
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
