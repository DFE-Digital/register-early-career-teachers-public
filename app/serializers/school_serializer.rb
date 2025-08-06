class SchoolSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    exclude :id

    field :name
    field(:urn) { |school, _| school.urn.to_s }
    field(:cohort) do |school, options|
      metadata = contract_period_metadata_for(school, options)
      metadata.contract_period_id.to_s
    end
    field(:in_partnership) do |school, options|
      metadata = contract_period_metadata_for(school, options)
      metadata.in_partnership
    end
    field(:induction_programme_choice) do |school, options|
      metadata = contract_period_metadata_for(school, options)
      metadata.induction_programme_choice
    end
    field(:expression_of_interest) do |school, options|
      metadata = lead_provider_contract_period_metadata_for(school, options)
      metadata.expression_of_interest
    end
    field :created_at
    field :updated_at

    class << self
      def contract_period_metadata_for(school, options)
        school.lead_provider_contract_period_metadata.find { it.contract_period_id == options[:contract_period].id } || default_metadata(contract_period_id: options[:contract_period].id)
      end

      def lead_provider_contract_period_metadata_for(school, options)
        school.lead_provider_contract_period_metadata.find { it.lead_provider_id == options[:lead_provider].id && it.contract_period_id == options[:contract_period].id } || default_metadata(contract_period_id: options[:contract_period].id)
      end

      def default_metadata(contract_period_id:)
        OpenStruct.new(in_partnership: false, contract_period_id:, induction_programme_choice: :not_yet_known, expression_of_interest: false)
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "school" }

  association :attributes, blueprint: AttributesSerializer do |school|
    school
  end
end
