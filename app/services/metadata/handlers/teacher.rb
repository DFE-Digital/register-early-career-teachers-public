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

        latest_ect_training_period = TrainingPeriod
          .includes(:ect_at_school_period)
          .where(ect_at_school_period: { teacher: } )
          .latest_first
          .started
          .find do |training_period|
            training_period.lead_provider.id == lead_provider_id
          end

        latest_mentor_training_period = TrainingPeriod
          .includes(:mentor_at_school_period)
          .where(mentor_at_school_period: { teacher: } )
          .latest_first
          .started
          .find do |training_period|
            training_period.lead_provider.id == lead_provider_id
          end

        upsert(metadata, latest_ect_training_period:, latest_mentor_training_period:)
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
