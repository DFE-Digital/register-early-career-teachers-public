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

        latest_ect_training_period = TrainingPeriod.ect_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
        latest_mentor_training_period = TrainingPeriod.mentor_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
        mentor_api_id = latest_ect_training_period&.trainee&.latest_mentorship_period&.mentor&.teacher&.api_id

        upsert(metadata, latest_ect_training_period:, latest_mentor_training_period:, mentor_api_id:)
      end
    end

    def all_lead_provider_ids
      LeadProvider.pluck(:id)
    end
  end
end
