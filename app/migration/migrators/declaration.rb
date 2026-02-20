module Migrators
  class Declaration < Migrators::Base
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
      training_period = training_period(participant_declaration:)
      declaration = ::Declaration
                      .find_or_initialize_by(api_id: participant_declaration.id,
                                             delivery_partner_when_created_id: training_period&.delivery_partner&.id)

      declaration.assign_attributes(api_updated_at: participant_declaration.updated_at,
                                    created_at: participant_declaration.created_at,
                                    clawback_statement_id: clawback_statement(participant_declaration:)&.id,
                                    clawback_status: participant_declaration.clawback_status,
                                    declaration_date: participant_declaration.declaration_date,
                                    declaration_type: participant_declaration.declaration_type,
                                    evidence_type: participant_declaration.evidence_held,
                                    payment_statement_id: payment_statement(participant_declaration:)&.id,
                                    payment_status: participant_declaration.payment_status,
                                    pupil_premium_uplift: participant_declaration.migrated_pupil_premium_uplift,
                                    sparsity_uplift: participant_declaration.migrated_sparsity_uplift,
                                    training_period_id: training_period&.id,
                                    updated_at: participant_declaration.updated_at,
                                    voided_by_user_at: participant_declaration.voided_at)

      declaration.save!(context: :being_migrated)
    end

  private

    def clawback_statement(participant_declaration:)
      if (ecf_clawback_statement_id = participant_declaration.clawback_statement&.id)
        statement_from_ecf_id(ecf_clawback_statement_id)
      end
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

    def payment_statement(participant_declaration:)
      if (ecf_payment_statement_id = participant_declaration.payment_statement&.id)
        statement_from_ecf_id(ecf_payment_statement_id)
      end
    end

    def preload_caches
      cache_manager.cache_delivery_partners
      cache_manager.cache_statements
      cache_manager.cache_teachers
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

    def training_period(participant_declaration:)
      teacher = teacher(participant_declaration:)
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
  end
end
