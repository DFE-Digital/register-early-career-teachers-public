class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, _|
      school.lead_provider_contract_period_metadata.first.contract_period.year
    end
    field(:in_partnership) do |school, _|
      school.lead_provider_contract_period_metadata.first.in_partnership
    end
    field(:induction_programme_choice) do |school, _|
      school.lead_provider_contract_period_metadata.first.induction_programme_choice
    end
    field(:expression_of_interest) do |school, _|
      school.lead_provider_contract_period_metadata.first.expression_of_interest
    end
    field :created_at
    field :updated_at
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
