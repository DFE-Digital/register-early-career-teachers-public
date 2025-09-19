class API::TransferSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:transfers) do |teacher, options|
      lead_provider = options[:lead_provider]
      training_periods = []

      teacher.ect_at_school_periods.each do |ect_at_school_period|
        ect_at_school_period.training_periods.each do |training_period|
          next if training_period.lead_provider != lead_provider

          training_periods << training_period
        end
      end

      teacher.mentor_at_school_periods.each do |mentor_at_school_period|
        mentor_at_school_period.training_periods.each do |training_period|
          next if training_period.lead_provider != lead_provider

          training_periods << training_period
        end
      end

      # Mocked result, not yet implemented on RECT
      training_periods.map do |training_period|
        trainee = training_period.trainee
        teacher = trainee.teacher
        training_record_id = training_period.for_ect? ? teacher.api_ect_profile_id : teacher.api_mentor_profile_id
        {
          training_record_id:,
          transfer_type: "leaving",
          status: "new_provider",
          created_at: trainee.created_at.rfc3339,
          leaving: {
            school_urn: trainee.school.urn,
            provider: training_period.lead_provider.name,
            date: training_period.finished_on&.strftime("%Y-%m-%d"),
          },
          joining: nil,
        }
      end
    end
  end

  # identifier :ecf_id, name: :id
  field(:type) { "participant-transfer" }

  association :attributes, blueprint: AttributesSerializer do |participant|
    participant
  end
end
