module Migrators
  class Declaration < Migrators::Base
    VOIDED_BY_USERS_ECF1_ECF2_MAPPING = {
      "7e3604f9-9777-4014-b948-16ee1cd5d946" => 189, # Lara Hughes
      "c1b7624b-6a41-4cdf-b37f-8972e934b018" => 29, # Colin Morris
      "f5770b20-ed06-421b-a2c9-9d10ce9ad52a" => 34 # Anna Knights
    }.freeze

    SPECIAL_DECLARATIONS_PATH = "special_declarations.csv"

    def self.record_count
      participant_declarations.count
    end

    def self.model
      :declaration
    end

    def self.participant_declarations
      ::Migration::ParticipantDeclaration
        .includes(:participant_profile, :statement_line_items, :cohort, cpd_lead_provider: :lead_provider)
        .not_superseded
        .not_ineligible
        .where.not(id: ero_mentor_declarations_to_exclude)
    end

    def self.ero_mentor_declarations_to_exclude
      ::Migration::ParticipantDeclaration
        .joins(participant_profile: :teacher_profile)
        .joins("inner join ecf_ineligible_participants eip on eip.trn = teacher_profiles.trn")
        .where(state: %w[voided submitted])
        .where(participant_profile: { type: "ParticipantProfile::Mentor" })
    end

    def self.dependencies
      %i[statement mentor ect]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Declaration.connection.execute("TRUNCATE #{::Declaration.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.participant_declarations) do |participant_declaration|
        migrate_one!(participant_declaration:)
      end
    end

    def migrate_one!(participant_declaration:)
      special_declaration = special_declaration(participant_declaration:)
      training_period = training_period(participant_declaration:, special_declaration:)
      declaration = ::Declaration
                      .find_or_initialize_by(api_id: participant_declaration.id,
                                             delivery_partner_when_created_id: training_period&.delivery_partner&.id)

      declaration.assign_attributes(api_updated_at: participant_declaration.updated_at,
                                    created_at: participant_declaration.created_at,
                                    clawback_statement_id: clawback_statement(participant_declaration:)&.id,
                                    clawback_status: participant_declaration.clawback_status,
                                    declaration_date: participant_declaration.declaration_date,
                                    declaration_type: participant_declaration.declaration_type,
                                    evidence_type: participant_declaration.migrated_evidence_held,
                                    payment_statement_id: payment_statement(participant_declaration:)&.id,
                                    payment_status: participant_declaration.payment_status,
                                    pupil_premium_uplift: participant_declaration.migrated_pupil_premium_uplift,
                                    sparsity_uplift: participant_declaration.migrated_sparsity_uplift,
                                    training_period_id: training_period&.id,
                                    updated_at: participant_declaration.updated_at,
                                    voided_by_user_at: participant_declaration.voided_at,
                                    voided_by_user_id: VOIDED_BY_USERS_ECF1_ECF2_MAPPING[participant_declaration.voided_by_user_id])

      declaration.save!(context: :being_migrated)
    end

  private

    def build_training_period(teacher:, participant_declaration:, special_declaration:)
      raise "Can't build a training period for declaration id #{participant_declaration.id}" unless special_declaration

      contract_period_year = find_contract_period_by_year!(participant_declaration.cohort.start_year).year
      delivery_partner_id = special_declaration[:delivery_partner_id]
      lead_provider = find_lead_provider_by_ecf_id!(participant_declaration.cpd_lead_provider.lead_provider.id)
      school = find_school_by_urn!(special_declaration[:urn])
      started_on = Date.new(contract_period_year, 9, 1)
      finished_on = started_on + 1.day
      at_school_periods = (participant_declaration.ect? ? teacher.ect_at_school_periods : teacher.mentor_at_school_periods)
                            .where(started_on: ..finished_on)
                            .order(started_on: :desc)

      at_school_period = create_at_school_period(teacher:, school:, started_on:, finished_on:, at_school_periods:)
      school_partnership = find_or_create_school_partnership(school:, lead_provider:, delivery_partner_id:, contract_period_year:)

      create_training_period(at_school_period:, school_partnership:)
    end

    def clawback_statement(participant_declaration:)
      if (ecf_clawback_statement_id = participant_declaration.clawback_statement&.id)
        statement_from_ecf_id(ecf_clawback_statement_id)
      end
    end

    def closest_training_period(teacher:, participant_declaration:)
      training_periods = participant_declaration.ect? ? teacher.ect_training_periods : teacher.mentor_training_periods

      training_periods
        .joins(school_partnership: {
          lead_provider_delivery_partnership: [
            :delivery_partner,
            { active_lead_provider: %i[lead_provider contract_period] }
          ]
        })
        .where(lead_provider: { ecf_id: participant_declaration.cpd_lead_provider.lead_provider.id },
               contract_period: { year: participant_declaration.cohort.start_year })
        .closest_to(participant_declaration.declaration_date)
        .first
    end

    def create_at_school_period(teacher:, school:, started_on:, finished_on:, at_school_periods:)
      at_school_periods.each do |at_school_period|
        break unless at_school_period.range.overlaps?(started_on..finished_on)

        started_on = at_school_period.started_on - 2.days
        finished_on = start_date + 1.day
      end

      teacher.ect_at_school_periods.create!(school:, started_on:, finished_on:)
    end

    def create_training_period(at_school_period:, school_partnership:)
      at_school_period.training_periods
                      .provider_led_training_programme
                      .create!(school_partnership:,
                               started_on: at_school_period.started_on,
                               finished_on: at_school_period.finished_on,
                               schedule: ::Schedule.find_by(contract_period_year: school_partnership.contract_period.year,
                                                            identifier: "ecf-standard-september"))
    end

    def delivery_partner_when_created(participant_declaration:)
      last_induction_record_for_lp = participant_declaration
                                       .participant_profile
                                       .induction_records
                                       .joins(induction_programme: { partnership: %i[lead_provider delivery_partner] })
                                       .where(lead_provider: { id: participant_declaration.cpd_lead_provider.lead_provider.id })
                                       .order(:created_at)
                                       .last
      delivery_partner = last_induction_record_for_lp&.induction_programme&.partnership&.delivery_partner

      find_delivery_partner_by_api_id!(delivery_partner.id) if delivery_partner
    end

    def find_or_create_school_partnership(school:, lead_provider:, delivery_partner_id:, contract_period_year:)
      active_lead_provider_id = find_active_lead_provider_id!(lead_provider_id: lead_provider.id, contract_period_year:)
      raise "Lead Provider (#{lead_provider.name}) no active on #{contract_period_year}. Can't build school partnership" unless active_lead_provider_id

      lpdp_id = cache_manager.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id:, delivery_partner_id:)&.id
      lpdp_id ||= ::LeadProviderDeliveryPartnership.create!(active_lead_provider_id:, delivery_partner_id:).id

      cache_manager.find_school_partnership(lead_provider_delivery_partnership_id: lpdp_id, school_id: school.id) ||
        school.school_partnerships.create!(lead_provider_delivery_partnership_id: lpdp_id)
    end

    def payment_statement(participant_declaration:)
      if (ecf_payment_statement_id = participant_declaration.payment_statement&.id)
        statement_from_ecf_id(ecf_payment_statement_id)
      end
    end

    def preload_caches
      cache_manager.cache_active_lead_providers
      cache_manager.cache_delivery_partners
      cache_manager.cache_lead_providers
      cache_manager.cache_lead_provider_delivery_partnerships
      cache_manager.cache_schools
      cache_manager.cache_school_partnerships
      cache_manager.cache_statements
      cache_manager.cache_teachers
    end

    def special_declaration(participant_declaration:)
      special_declarations.find { it[:declaration_id] == participant_declaration.id }
    end

    def special_declarations
      @special_declarations ||= CSV.table(SPECIAL_DECLARATIONS_PATH)
    end

    def statement_from_ecf_id(id)
      find_statement_by_api_id!(id) if id
    end

    def teacher(participant_declaration:)
      if participant_declaration.ect?
        find_teacher_by_api_ect_training_record_id!(participant_declaration.participant_profile_id)
      else
        find_teacher_by_api_mentor_training_record_id!(participant_declaration.participant_profile_id)
      end
    end

    def training_period(participant_declaration:, special_declaration:)
      teacher = teacher(participant_declaration:)

      closest_training_period(teacher:, participant_declaration:) ||
        build_training_period(teacher:, participant_declaration:, special_declaration:)
    end
  end
end
