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

        # TBD: `mentor_id` or `latest_ect_training_period_mentor_id`
        # should we save api_id of the mentor teacher or just the id?
        # recording the api_id would make lookups easier but following the pattern of other metadata which saves ids
        # would require an additional join to fetch the api_id in the API query
        mentor_id = latest_ect_training_period&.latest_mentorship_period&.mentor&.teacher&.api_id

        upsert(metadata, latest_ect_training_period:, latest_mentor_training_period:, mentor_id:)
      end
    end

    def all_lead_provider_ids
      LeadProvider.pluck(:id)
    end
  end
end
