class API::Teachers::UnfundedMentorSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:full_name) { |teacher| Teachers::Name.new(teacher).full_name_in_trs }
    field(:email) do |teacher, _options|
      teacher.latest_mentor_at_school_period.email
    end
    field(:trn, name: :teacher_reference_number)
    field :created_at

    # TODO: use `api_unfunded_mentor_updated_at` once we have added it
    field(:api_updated_at, name: :updated_at)
  end

  identifier :api_id, name: :id
  field(:type) { "unfunded-mentor" }

  association :attributes, blueprint: AttributesSerializer do |teacher|
    teacher
  end
end
