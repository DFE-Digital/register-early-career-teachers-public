class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]

      latest_ect_training_period = TrainingPeriod
        .includes(:ect_at_school_period)
        .where(ect_at_school_period: { teacher: } )
        .latest_first
        .started
        .find do |training_period|
          training_period.lead_provider == lead_provider
        end

      latest_mentor_training_period = TrainingPeriod
        .includes(:mentor_at_school_period)
        .where(mentor_at_school_period: { teacher: } )
        .latest_first
        .started
        .find do |training_period|
          training_period.lead_provider == lead_provider
        end

      [latest_ect_training_period, latest_mentor_training_period].compact.map do |training_period|
        ecf_enrolment(training_period)
      end
    end

    class << self
      def ecf_enrolment(training_period)
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_training_record_id : teacher.api_mentor_training_record_id
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
