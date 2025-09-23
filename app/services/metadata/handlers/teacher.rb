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
        metadata = Metadata::TeacherLeadProvider.find_or_initialize_by(
          teacher:,
          lead_provider_id:
        )

        ect_training_record_created_at = teacher.ect_at_school_periods
          .includes(training_periods: :lead_provider)
          .where(lead_providers: { id: lead_provider_id })
          .earliest_first
          .first&.created_at

        mentor_training_record_created_at = teacher.mentor_at_school_periods
          .includes(training_periods: :lead_provider)
          .where(lead_providers: { id: lead_provider_id })
          .earliest_first
          .first&.created_at

        upsert(metadata, ect_training_record_created_at:, mentor_training_record_created_at:)
      end
    end

    def lead_provider_ids
      (
        teacher.ect_at_school_periods.includes(training_periods: :lead_provider).pluck(:lead_provider_id) +
        teacher.mentor_at_school_periods.includes(training_periods: :lead_provider).pluck(:lead_provider_id)
      ).compact.uniq
    end
  end
end
