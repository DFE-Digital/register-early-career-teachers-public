class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]

      metadata = metadata(teacher, lead_provider)

      [metadata.latest_ect_training_period, metadata.latest_mentor_training_period].compact.map do |training_period|
        ecf_enrolment(metadata, training_period)
      end
    end

    class << self
      def metadata(teacher, lead_provider)
        teacher.lead_provider_metadata.select { it.lead_provider_id == lead_provider.id }.sole
      end

      def ecf_enrolment(metadata, training_period)
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_training_record_id : teacher.api_mentor_training_record_id
        {
          training_record_id:,
          email: trainee.email,
          mentor_id: metadata.mentor_id,
          participant_type: training_period.for_ect? ? "ect" : "mentor",
        }
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |participant|
    participant
  end
end
