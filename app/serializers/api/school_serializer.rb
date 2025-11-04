class API::SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) do |school, _|
      school.urn.to_s
    end
    field(:cohort) do |_, options|
      options[:contract_period_year].to_s
    end
    field(:in_partnership) do |school, options|
      contract_period_metadata(school:, options:).in_partnership
    end
    field(:induction_programme_choice) do |school, options|
      contract_period_metadata(school:, options:).induction_programme_choice
    end
    field(:expression_of_interest) do |school, options|
      expression_of_interest_or_school_partnership(school:, options:)
    end
    field :induction_tutor_name do |school, options|
      school.induction_tutor_name if expression_of_interest_or_school_partnership(school:, options:)
    end
    field :induction_tutor_email do |school, options|
      school.induction_tutor_email if expression_of_interest_or_school_partnership(school:, options:)
    end
    field :created_at
    field(:api_updated_at, name: :updated_at)

    class << self
      def expression_of_interest_or_school_partnership(school:, options:)
        @expression_of_interest_or_school_partnership ||= {}
        @expression_of_interest_or_school_partnership["#{school.id},#{options}"] ||= lead_provider_contract_period_metadata(school:, options:).expression_of_interest_or_school_partnership
      end

      def contract_period_metadata(school:, options:)
        school.contract_period_metadata.select { it.contract_period_year == options[:contract_period_year] }.sole
      end

      def lead_provider_contract_period_metadata(school:, options:)
        school.lead_provider_contract_period_metadata.select { |it|
          it.lead_provider_id == options[:lead_provider_id] && it.contract_period_year == options[:contract_period_year]
        }.sole
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
