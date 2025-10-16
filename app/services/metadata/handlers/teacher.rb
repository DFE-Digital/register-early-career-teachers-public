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
      existing_metadata = Metadata::TeacherLeadProvider
              .where(teacher:, lead_provider_id: lead_provider_ids)
              .index_by(&:lead_provider_id)

      changes_to_upsert = []

      lead_provider_ids.each do |lead_provider_id|
        metadata = existing_metadata[lead_provider_id] ||
          Metadata::TeacherLeadProvider.new(teacher:, lead_provider_id:)

        latest_ect_training_period = TrainingPeriod.ect_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
        latest_mentor_training_period = TrainingPeriod.mentor_training_periods_latest_first(teacher:, lead_provider: lead_provider_id).first
        api_mentor_id = latest_ect_training_period&.trainee&.latest_mentorship_period&.mentor&.teacher&.api_id

        changes = {
          teacher_id: teacher.id,
          lead_provider_id:,
          latest_ect_training_period_id: latest_ect_training_period&.id,
          latest_mentor_training_period_id: latest_mentor_training_period&.id,
          api_mentor_id:
        }

        next if metadata.attributes.slice(*changes.keys) == changes

        alert_on_changes(metadata:, changes:)
        changes_to_upsert << changes
      end

      Metadata::TeacherLeadProvider.upsert_all(changes_to_upsert, unique_by: %i[teacher_id lead_provider_id])
    end
  end
end
