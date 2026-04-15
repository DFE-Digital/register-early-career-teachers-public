module Migrators
  class Declaration < Migrators::Base
    VOIDED_BY_USERS_ECF1_ECF2_MAPPING = {
      "7e3604f9-9777-4014-b948-16ee1cd5d946" => 189, # Lara Hughes
      "c1b7624b-6a41-4cdf-b37f-8972e934b018" => 29, # Colin Morris
      "f5770b20-ed06-421b-a2c9-9d10ce9ad52a" => 34 # Anna Knights
    }.freeze

    SPECIAL_DECLARATIONS_PATH = "app/migration/migrators/special_declarations.csv"

    class ActiveLeadProviderNotFoundError < StandardError; end
    class LeadProviderDeliveryPartnershipNotFoundError < StandardError; end
    class SchoolPartnershipNotFoundError < StandardError; end

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

    def clawback_statement(participant_declaration:)
      if (ecf_clawback_statement_id = participant_declaration.clawback_statement&.id)
        statement_from_ecf_id(ecf_clawback_statement_id)
      end
    end

    def create_training_period(at_school_period:, school_partnership:, started_on:, finished_on:)
      schedule = ::Schedule.find_by(contract_period_year: school_partnership.contract_period.year,
                                    identifier: "ecf-standard-september")
      at_school_period.training_periods
                      .provider_led_training_programme
                      .create!(school_partnership:,
                               started_on:,
                               finished_on:,
                               schedule:,
                               created_at: at_school_period.created_at,
                               updated_at: at_school_period.updated_at)
    end

    # Finds a date to create an at_school_period starting from started_on backwards, so that
    # a 1-day ASP can be created without overlapping any existing teacher ASPs.
    def date_for_new_training_period(at_school_periods:, started_on:)
      finished_on = started_on + 1.day
      potential_at_school_periods = at_school_periods.select { it.started_on <= finished_on }
      potential_at_school_periods.sort_by(&:started_on).reverse_each do |at_school_period|
        break unless at_school_period.range.overlaps?(started_on..finished_on)

        started_on = at_school_period.started_on - 2.days
      end

      started_on
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

    def school_partnership_for(school:, lead_provider:, delivery_partner_id:, contract_period_year:, participant_declaration_id:)
      active_lead_provider_id = find_active_lead_provider_id!(lead_provider_id: lead_provider.id, contract_period_year:)
      raise(ActiveLeadProviderNotFoundError, "Lead Provider (#{lead_provider.name}) no active on #{contract_period_year}. Can't migrate declaration #{participant_declaration_id}") unless active_lead_provider_id

      lpdp_id = cache_manager.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id:, delivery_partner_id:)&.id
      raise(LeadProviderDeliveryPartnershipNotFoundError, "Lead Provider Delivery Partnership not found for Lead Provider #{lead_provider.name} and Delivery Partner id #{delivery_partner_id} on #{contract_period_year}. Can't migrate declaration #{participant_declaration_id}") unless lpdp_id

      cache_manager.find_school_partnership(lead_provider_delivery_partnership_id: lpdp_id, school_id: school.id).tap do |school_partnership|
        raise(SchoolPartnershipNotFoundError, "School Partnership not found for Lead Provider #{lead_provider.name}, Delivery Partner id #{delivery_partner_id} at School #{school.urn} on #{contract_period_year}. Can't migrate declaration #{participant_declaration_id}") unless school_partnership
      end
    end

    # For the participant declaration, find teacher TP matching exactly lead_provider, delivery_partner, school and contract_period
    # that contains the declaration date
    # Otherwise nil is returned.
    def fully_matching_training_period(training_periods:, lead_provider:, delivery_partner_id:, contract_period_year:, school:, declaration_date:)
      return unless contract_period_year && lead_provider && delivery_partner_id

      training_periods.find do
        (school.nil? || it.school_id == school.id) &&
          it.contract_period&.year == contract_period_year &&
          it.lead_provider == lead_provider &&
          it.delivery_partner.id == delivery_partner_id &&
          (it.range.include?(declaration_date))
      end
    end

    # Create an ASP and TP for the participant declaration in a date that do not overlap with existing teacher at school periods.
    # Also, a stub school partnership might be created if none matches the declaration combo.
    def make_training_period(teacher:, participant_declaration:, school:, lead_provider:, delivery_partner_id:, contract_period_year:, started_on:)
      at_school_period_class = participant_declaration.ect? ? ECTAtSchoolPeriod : MentorAtSchoolPeriod
      at_school_periods = (participant_declaration.ect? ? teacher.ect_at_school_periods : teacher.mentor_at_school_periods).to_a
      started_on = date_for_new_training_period(at_school_periods:, started_on:)
      finished_on = started_on + 1.day
      at_school_period = at_school_period_class.create!(teacher:, school:, started_on:, finished_on:).tap do |period|
        if at_school_periods.none?
          period.update!(created_at: participant_declaration.participant_profile.created_at,
                         updated_at: participant_declaration.participant_profile.created_at)
        end
      end
      school_partnership = school_partnership_for(school:, lead_provider:, delivery_partner_id:, contract_period_year:, participant_declaration_id: participant_declaration.id)

      create_training_period(at_school_period:, school_partnership:, started_on:, finished_on:)
    end

    # For the participant declaration, find a teacher TP matching exactly lead_provider, delivery_partner, school and contract_period
    # being the most recent starting before declaration date or the less recent
    # Otherwise nil is returned.
    def matching_closest_earlier_training_period(training_periods:, lead_provider:, delivery_partner_id:, contract_period_year:, school:, declaration_date:)
      return unless contract_period_year && lead_provider && delivery_partner_id

      matching = training_periods.select do
        (school.nil? || it.school_id == school.id) &&
          it.contract_period&.year == contract_period_year &&
          it.lead_provider == lead_provider &&
          it.delivery_partner.id == delivery_partner_id
      end
      matching = matching.sort_by(&:started_on).reverse
      past_more_recent = matching.find { it.started_on < declaration_date }
      past_more_recent || matching.last
    end

    # For the participant declaration, find teacher TP matching exactly lead_provider and contract_period
    # being the most recent starting before declaration date or the less recent.
    # Otherwise nil is returned.
    def matching_closest_earlier_training_period_no_dp(training_periods:, lead_provider:, contract_period_year:, declaration_date:)
      matching = training_periods.select do
        it.contract_period&.year == contract_period_year &&
          it.lead_provider == lead_provider
      end
      matching = matching.sort_by(&:started_on).reverse
      past_more_recent = matching.find { it.started_on < declaration_date }
      past_more_recent || matching.last
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
      special_declarations.find { it[:participant_declaration_id] == participant_declaration.id }
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

    # Try to provide a training_period for the participant declaration:
    #   1. Try and find a TP matching teacher, lead_provider, delivery_partner, school and contract_period, or
    #   2. If the declaration is special, build a TP trying backwards from the first of September of the declaration cohort, or
    #   3. Try and find the closest teacher TP matching the declaration lead_provider and contract_period.
    def training_period(participant_declaration:, special_declaration:)
      teacher = teacher(participant_declaration:)
      declaration_date = participant_declaration.declaration_date
      contract_period_year = find_contract_period_by_year!(participant_declaration.cohort.start_year).year
      lead_provider = find_lead_provider_by_ecf_id!(participant_declaration.cpd_lead_provider.lead_provider.id)
      delivery_partner_api_id = special_declaration ? special_declaration[:delivery_partner_id] : participant_declaration.delivery_partner_id
      delivery_partner_id = find_delivery_partner_by_api_id!(delivery_partner_api_id).id if delivery_partner_api_id
      school = find_school_by_urn!(special_declaration[:urn]) if special_declaration
      started_on = Date.new(contract_period_year, 9, 1)
      training_periods = participant_declaration.ect? ? teacher.ect_training_periods : teacher.mentor_training_periods
      training_periods = training_periods
                           .includes(school_partnership: {
                             lead_provider_delivery_partnership: [
                               :delivery_partner,
                               { active_lead_provider: %i[lead_provider contract_period] }
                             ]
                           }).to_a
      training_period = fully_matching_training_period(training_periods:, lead_provider:, delivery_partner_id:, contract_period_year:, school:, declaration_date:)
      training_period ||= matching_closest_earlier_training_period(training_periods:, lead_provider:, delivery_partner_id:, contract_period_year:, school:, declaration_date:)
      return training_period if training_period

      if special_declaration
        make_training_period(teacher:, participant_declaration:, school:, lead_provider:, delivery_partner_id:, contract_period_year:, started_on:)
      else
        matching_closest_earlier_training_period_no_dp(training_periods:, lead_provider:, contract_period_year:, declaration_date:)
      end
    end
  end
end
