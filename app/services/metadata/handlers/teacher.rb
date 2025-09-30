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
      all_lead_provider_ids.each do |lead_provider_id|
        metadata = Metadata::TeacherLeadProvider.find_or_initialize_by(
          teacher:,
          lead_provider_id:
        )

        latest_ect_training_period = TrainingPeriod
          .includes(:ect_at_school_period, :lead_provider)
          .where(ect_at_school_period: { teacher: }, lead_provider: { id: lead_provider_id })
          .latest_first
          .first

        latest_mentor_training_period = TrainingPeriod
          .includes(:mentor_at_school_period, :lead_provider)
          .where(mentor_at_school_period: { teacher: }, lead_provider: { id: lead_provider_id })
          .latest_first
          .first

        upsert(metadata, latest_ect_training_period:, latest_mentor_training_period:)
      end
    end

    def all_lead_provider_ids
      LeadProvider.pluck(:id)
    end
  end
end
