class API::ParticipantSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    # object is Teacher
    field(:ecf_enrolments) do |object, options|
      lead_provider = options[:lead_provider]

      ecf_enrolments = []
      object.ect_at_school_periods.each do |ect_at_school_period|
        ect_at_school_period.training_periods.each do |training_period|
          next if training_period.lead_provider != lead_provider

          ecf_enrolments << ecf_enrolment(training_period)
        end
      end

      object.mentor_at_school_periods.each do |mentor_at_school_period|
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
        teacher = trainee.teacher
        {
          training_record_id: training_period.id,
          email: trainee.email,
          mentor_id: (teacher.ecf_user_id if training_period.for_ect?),

          pupil_premium_uplift: teacher.ect_pupil_premium_uplift,
          sparsity_uplift: teacher.ect_sparsity_uplift,
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
