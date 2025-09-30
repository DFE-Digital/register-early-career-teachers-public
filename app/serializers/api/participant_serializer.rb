class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]

      (teacher.ect_at_school_periods + teacher.mentor_at_school_periods).map { |trainee|
        training_period = latest_training_period(trainee, lead_provider)
        next unless training_period

        ecf_enrolment(training_period)
      }.compact
    end

    class << self
      def latest_training_period(trainee, lead_provider)
        trainee.training_periods.sort_by(&:started_on).reverse.find do |training_period|
          training_period.lead_provider == lead_provider
        end
      end

      def ecf_enrolment(training_period)
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_training_record_id : teacher.api_mentor_training_record_id
        {
          training_record_id:,
          email: trainee.email,
          mentor_id_1: training_period.for_ect? ? trainee.latest_mentorship_period&.mentor&.teacher&.api_id : nil,
          mentor_id_2: training_period.for_ect? ? training_period.latest_mentorship_period&.mentor&.teacher&.api_id : nil,
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
