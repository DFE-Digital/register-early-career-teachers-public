class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:ecf_enrolments) do |teacher, options|
      lead_provider = options[:lead_provider]
      ecf_enrolments = []

      teacher.ect_at_school_periods.each do |ect_at_school_period|
        ect_at_school_period.training_periods.each do |training_period|
          next if training_period.lead_provider != lead_provider

          ecf_enrolments << ecf_enrolment(training_period)
        end
      end

      teacher.mentor_at_school_periods.each do |mentor_at_school_period|
        mentor_at_school_period.training_periods.each do |training_period|
          next if training_period.lead_provider != lead_provider

          ecf_enrolments << ecf_enrolment(training_period)
        end
      end

      ecf_enrolments.compact
    end

    class << self
      def ecf_enrolment(training_period)
        trainee = training_period.trainee
        {
          training_record_id: training_period.id,
          email: trainee.email,

          pupil_premium_uplift: (trainee.pupil_premium_uplift if training_period.for_ect?),
          sparsity_uplift: (trainee.sparsity_uplift if training_period.for_ect?),
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
