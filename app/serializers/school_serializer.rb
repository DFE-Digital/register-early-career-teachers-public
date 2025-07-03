class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |_school, options|
      options[:registration_period_id]&.to_s
    end
    field(:in_partnership) do |school, options|
      school.in_partnership_for?(
        registration_period_id: options[:registration_period_id]
      )
    end
    field(:induction_programme_choice) do |school, options|
      school.training_programme_for(
        registration_period_id: options[:registration_period_id]
      )
    end
    field(:expression_of_interest) do |school, options|
      school.expressions_of_interest_for?(
        lead_provider_id: options[:lead_provider_id],
        registration_period_id: options[:registration_period_id]
      )
    end
    field :created_at
    field :updated_at
    # field(:updated_at) do |school, _options|
    #   [
    #     school.api_updated_at,
    #     school.updated_at,
    #   ].compact.max
    # end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
