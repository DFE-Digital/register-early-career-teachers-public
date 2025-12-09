class API::SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name do |data|
      data[:school].name
    end
    field(:urn) do |data|
      data[:school].urn.to_s
    end
    field(:cohort) do |_, options|
      options[:contract_period_year].to_s
    end
    field(:in_partnership) do |data, options|
      contract_period_metadata(school: data[:school], options:).in_partnership
    end
    field(:induction_programme_choice) do |data, options|
      contract_period_metadata(school: data[:school], options:).induction_programme_choice
    end
    field(:expression_of_interest) do |data|
      data[:expression_of_interest_or_school_partnership]
    end
    field :induction_tutor_name do |data|
      data[:school].induction_tutor_name if data[:expression_of_interest_or_school_partnership]
    end
    field :induction_tutor_email do |data|
      data[:school].induction_tutor_email if data[:expression_of_interest_or_school_partnership]
    end
    field :created_at do |data|
      data[:school].created_at
    end
    field(:updated_at) do |data|
      data[:school].api_updated_at
    end

    class << self
      def contract_period_metadata(school:, options:)
        school.contract_period_metadata.select { it.contract_period_year == options[:contract_period_year] }.sole
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school, options|
    lead_provider_contract_period_metadata = school.lead_provider_contract_period_metadata.select { |it|
      it.lead_provider_id == options[:lead_provider_id] && it.contract_period_year == options[:contract_period_year]
    }.sole

    expression_of_interest_or_school_partnership = lead_provider_contract_period_metadata.expression_of_interest_or_school_partnership

    { school:, expression_of_interest_or_school_partnership: }
  end
end
