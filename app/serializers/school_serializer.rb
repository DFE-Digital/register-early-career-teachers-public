class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, _|
      metadata(school).contract_period.year.to_s
    end
    field(:in_partnership) do |school, _|
      metadata(school).in_partnership
    end
    field(:induction_programme_choice) do |school, _|
      metadata(school).induction_programme_choice
    end
    field(:expression_of_interest) do |school, _|
      metadata(school).expression_of_interest
    end
    field :created_at
    field :updated_at

    class << self
      def metadata(school)
        school.lead_provider_contract_period_metadata.first
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
