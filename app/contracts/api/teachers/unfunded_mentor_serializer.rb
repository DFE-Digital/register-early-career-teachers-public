class API::Teachers::UnfundedMentorSerializer < Blueprinter::Base
  def self.dependencies
    [
      { lead_provider_metadata_for_mentees: :ect_assigned_mentor_latest_school_period }
    ]
  end

  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field(:full_name) { |teacher| Teachers::Name.new(teacher).full_name }
    # Email is derived from the latest mentor assignment for the requested lead
    # provider. Consequently, direct email changes on the mentor will result in the
    # `updated_at` changing, however mentor assignments that result in email changes
    # will not be reflected in the `updated_at` timestamp.
    field(:email) do |teacher, options|
      lead_provider_id = options[:lead_provider_id]

      teacher.lead_provider_metadata_for_mentees
        .select { |m| m.lead_provider_id == lead_provider_id }
        .max_by { |m| m.ect_assigned_mentor_latest_school_period.started_on }
        .ect_assigned_mentor_latest_school_period
        .email
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
