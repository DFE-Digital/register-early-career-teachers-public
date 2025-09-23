class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]

      (teacher.ect_at_school_periods + teacher.mentor_at_school_periods).map { |trainee|
        training_period = latest_training_period(trainee, lead_provider)
        next unless training_period

        ecf_enrolment(training_period, lead_provider)
      }.compact
    end

    class << self
      def latest_training_period(trainee, lead_provider)
        # `training_periods` already preloaded, sort in memory
        trainee.training_periods.sort_by(&:started_on).reverse.find do |training_period|
          training_period.lead_provider == lead_provider
        end
      end

      def ecf_enrolment(training_period, lead_provider)
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_training_record_id : teacher.api_mentor_training_record_id

        metadata = lead_provider_metadata(teacher:, lead_provider:)
        created_at = training_period.for_ect? ? metadata.ect_training_record_created_at : metadata.mentor_training_record_created_at
        {
          training_record_id:,
          email: trainee.email,
          participant_type: training_period.for_ect? ? "ect" : "mentor",
          lead_provider: training_period.lead_provider.name,
          created_at: created_at&.rfc3339,
        }
      end

      def lead_provider_metadata(teacher:, lead_provider:)
        teacher.lead_provider_metadata.select { it.lead_provider_id == lead_provider.id }.sole
      end
    end
  end

  # identifier :ecf_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |participant|
    participant
  end
end
