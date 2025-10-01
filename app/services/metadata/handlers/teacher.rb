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

        latest_ect_training_period = TrainingPeriod.latest_ect_training_period(teacher:, lead_provider: lead_provider_id).first
        latest_mentor_training_period = TrainingPeriod.latest_mentor_training_period(teacher:, lead_provider: lead_provider_id).first

        upsert(metadata, latest_ect_training_period:, latest_mentor_training_period:)
      end
    end

    def all_lead_provider_ids
      LeadProvider.pluck(:id)
    end
  end
end
