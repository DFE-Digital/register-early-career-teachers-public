class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]

      (teacher.ect_at_school_periods + teacher.mentor_at_school_periods).map { |trainee|
        training_period = trainee.latest_training_period
        next unless training_period&.lead_provider == lead_provider

        ecf_enrolment(training_period)
      }.compact
    end

    class << self
      def ecf_enrolment(training_period)
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_profile_id : teacher.api_mentor_profile_id
        {
          school_period_id: trainee.id,
          training_record_id:,
          email: trainee.email,
          participant_type: training_period.for_ect? ? "ect" : "mentor",
          started_on: training_period.started_on&.iso8601,
          finished_on: training_period.finished_on&.iso8601,
          lead_provider: training_period.lead_provider.name,
        }
      end
    end
  end

  # identifier :ecf_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |participant|
    participant
  end
end
