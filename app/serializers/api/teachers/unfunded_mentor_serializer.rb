class API::Teachers::UnfundedMentorSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:full_name) { |teacher| Teachers::Name.new(teacher).full_name }
    field(:email) do |teacher, options|
      lead_provider_id = options[:lead_provider_id]

      matching_periods = teacher.mentor_at_school_periods.select do |masp|
        masp.mentorship_periods.any? do |msp|
          msp.mentee.training_periods.any? { |tp| tp.active_lead_provider&.lead_provider_id == lead_provider_id }
        end
      end

      matching_periods.max_by(&:started_on).email
    end
    field(:trn, name: :teacher_reference_number)
    field :created_at
    field(:api_unfunded_mentor_updated_at, name: :updated_at)
  end

  identifier :api_id, name: :id
  field(:type) { "unfunded-mentor" }

  association :attributes, blueprint: AttributesSerializer do |teacher|
    teacher
  end
end
