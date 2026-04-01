module Metadata::Handlers
  class Teacher < Base
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def refresh_metadata!
      upsert_lead_provider_metadata!
    end

    class << self
      def destroy_all_metadata!
        truncate_models!(Metadata::TeacherLeadProvider)
      end
    end

  private

    def upsert_lead_provider_metadata!
      lead_provider_ids.each do |lead_provider_id|
        metadata = existing_lead_provider_metadata(lead_provider_id:) ||
          Metadata::TeacherLeadProvider.new(teacher:, lead_provider_id:)

        latest_ect_training_period = latest_ect_training_period_by_lead_provider(teacher:, lead_provider_id:)
        latest_mentor_training_period = latest_mentor_training_period_by_lead_provider(teacher:, lead_provider_id:)
        latest_ect_contract_period = latest_ect_training_period&.contract_period
        latest_mentor_contract_period = latest_mentor_training_period&.contract_period
        api_mentor_id = latest_ect_training_period&.at_school_period&.latest_mentorship_period&.mentor&.teacher&.api_id
        involved_in_school_transfer = school_transfers_exist_for(teacher.ect_at_school_periods, lead_provider_id) ||
          school_transfers_exist_for(teacher.mentor_at_school_periods, lead_provider_id)

        changes = {
          teacher_id: teacher.id,
          lead_provider_id:,
          latest_ect_training_period_id: latest_ect_training_period&.id,
          latest_mentor_training_period_id: latest_mentor_training_period&.id,
          latest_ect_contract_period_year: latest_ect_contract_period&.year,
          latest_mentor_contract_period_year: latest_mentor_contract_period&.year,
          api_mentor_id:,
          involved_in_school_transfer:
        }

        commit_changes!(metadata, changes)
      end
    end

    def existing_lead_provider_metadata(lead_provider_id:)
      @existing_lead_provider_metadata ||= {}
      @existing_lead_provider_metadata[lead_provider_id] ||= Metadata::TeacherLeadProvider
      .includes(
        latest_ect_training_period: {
          school_partnership: [
            { school: :school_funding_eligibilities },
            { lead_provider_delivery_partnership: :delivery_partner }
          ],
          ect_at_school_period: {
            school: [],
            teacher: { finished_induction_period: [], ect_at_school_periods: [] }
          },
          schedule: :contract_period,
          contract_period: [],
          lead_provider: [],
        },
        latest_ect_contract_period: [],
        latest_mentor_training_period: {
          school_partnership: [
            { school: :school_funding_eligibilities },
            { lead_provider_delivery_partnership: :delivery_partner }
          ],
          mentor_at_school_period: {
            school: [],
            teacher: { mentor_at_school_periods: [] }
          },
          schedule: :contract_period,
          contract_period: [],
          lead_provider: [],
        },
        latest_mentor_contract_period: []
      )
      .find_by(teacher:, lead_provider_id:)
    end

    def latest_ect_training_period_by_lead_provider(teacher:, lead_provider_id:)
      @latest_ect_training_period_by_lead_provider ||= {}
      @latest_ect_training_period_by_lead_provider[lead_provider_id] ||= TrainingPeriod
        .includes(:contract_period, :lead_provider, ect_at_school_period: { latest_mentorship_period: { mentor: :teacher } })
        .where(ect_at_school_period: { teacher: })
        .select("DISTINCT ON (active_lead_providers.lead_provider_id) training_periods.*")
        .order("active_lead_providers.lead_provider_id, training_periods.started_on DESC")
        .index_by { it.lead_provider&.id }[lead_provider_id]
    end

    def latest_mentor_training_period_by_lead_provider(teacher:, lead_provider_id:)
      @latest_mentor_training_period_by_lead_provider ||= {}
      @latest_mentor_training_period_by_lead_provider[lead_provider_id] ||= TrainingPeriod
      .includes(:contract_period, :lead_provider, :mentor_at_school_period)
      .where(mentor_at_school_period: { teacher: })
      .select("DISTINCT ON (active_lead_providers.lead_provider_id) training_periods.*")
      .order("active_lead_providers.lead_provider_id, training_periods.started_on DESC")
      .index_by { it.lead_provider&.id }[lead_provider_id]
    end

    def school_transfers_exist_for(school_periods, lead_provider_id)
      ::API::Teachers::SchoolTransfers::History.exists_for?(school_periods:, lead_provider_id:)
    end
  end
end
